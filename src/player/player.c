//acknowledgement: https://github.com/ilongshan/simple-audio-c99

#include <libavformat/avformat.h>
#include <libavresample/avresample.h>
#include <ao/ao.h>

#define OUTPUT_BITS 16
#define OUTPUT_CHANNELS 2
#define OUTPUT_RATE 48000

typedef struct AudioFile {
    char *path;
    AVFormatContext *formatContext;
    AVCodec *codec;
    AVCodecContext *codecContext;
} AudioFile;

int loadAudioError;
int av_register_all_called = 0;

AudioFile *loadAudio(char *path) {
    loadAudioError = 0;
    int err = 0;
    int i = 0;

    AudioFile *audioFile = malloc(sizeof(AudioFile));
    audioFile->path = path;
    if (av_register_all_called == 0) {
        av_register_all();
        av_register_all_called = 1;
    }

    audioFile->formatContext = NULL;
    err = avformat_open_input(&audioFile->formatContext, path, NULL, NULL);
    if (err != 0) {
        loadAudioError = 2;
        avformat_close_input(&audioFile->formatContext);
        return NULL;
    }

    err = avformat_find_stream_info(audioFile->formatContext, NULL);
    if (err != 0) {
        loadAudioError = 3;
        avformat_close_input(&audioFile->formatContext);
        return NULL;
    }

    int streamIndex = -1;
    for (i = 0; i < audioFile->formatContext->nb_streams; i++) {
        if (audioFile->formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            streamIndex = i;
            break;
        }
    }
    if (streamIndex == -1) {
        loadAudioError = 4;
        avformat_close_input(&audioFile->formatContext);
        return NULL;
    }

    audioFile->codec = avcodec_find_decoder(audioFile->formatContext->streams[i]->codecpar->codec_id);
    if (audioFile->codec == NULL) {
       loadAudioError = 5;
        avformat_close_input(&audioFile->formatContext);
        return NULL;
    }

    audioFile->codecContext = avcodec_alloc_context3(audioFile->codec);
    err = avcodec_parameters_to_context(audioFile->codecContext, audioFile->formatContext->streams[i]->codecpar);
    if (err != 0) {
        loadAudioError = 6;
        avformat_close_input(&audioFile->formatContext);
        avcodec_free_context(&audioFile->codecContext);
        return NULL;
    }

    err = avcodec_open2(audioFile->codecContext, audioFile->codec, NULL);

    if (err != 0) {
        loadAudioError = 7;
        avformat_close_input(&audioFile->formatContext);
        avcodec_free_context(&audioFile->codecContext);
        return NULL;
    }

    return audioFile;
}

void playAudio(AudioFile *audioFile) {
    int i = 0;

    ao_initialize();
    int defaultDriver = ao_default_driver_id();
    ao_info *info = ao_driver_info(defaultDriver);
    ao_sample_format *sampleFormat = malloc(sizeof(ao_sample_format));
    sampleFormat->bits = OUTPUT_BITS;
    sampleFormat->channels = OUTPUT_CHANNELS;
    sampleFormat->rate = OUTPUT_RATE;
    sampleFormat->byte_format = info->preferred_byte_format;
    sampleFormat->matrix = 0;
    ao_device *device = ao_open_live(defaultDriver, sampleFormat, NULL);
 
    if (device == NULL) {
        free(sampleFormat);
        ao_close(device);
        ao_shutdown();
    }

    AVAudioResampleContext *resampleContext = avresample_alloc_context();
    av_opt_set_int(resampleContext, "in_channel_layout",av_get_default_channel_layout(audioFile->codecContext->channels), 0);
    av_opt_set_int(resampleContext, "out_channel_layout",av_get_default_channel_layout(sampleFormat->channels), 0);
    av_opt_set_int(resampleContext, "in_sample_rate",audioFile->codecContext->sample_rate, 0);
    av_opt_set_int(resampleContext, "out_sample_rate",sampleFormat->rate, 0);
    av_opt_set_int(resampleContext, "in_sample_fmt",audioFile->codecContext->sample_fmt, 0);
    av_opt_set_int(resampleContext, "out_sample_fmt",AV_SAMPLE_FMT_S16, 0);

    avresample_open(resampleContext);
    avformat_seek_file(audioFile->formatContext, 0, 0, 0, 0, 0);

    int64_t outputSampleFormat;
    av_opt_get_int(resampleContext, "out_sample_fmt", 0, &outputSampleFormat);

    AVPacket packet = {0};
    av_init_packet(&packet);

    AVFrame *frame = av_frame_alloc();

    int gotFrame = 0;
    int count = 0;
    int outputSampleCount = 0;
    uint8_t *output;
    int outputLineSize;

    for (;;) {
        if (av_read_frame(audioFile->formatContext, &packet)) {
            break;
        }
        gotFrame = 0;
        count = avcodec_decode_audio4(audioFile->codecContext, frame, &gotFrame, &packet);
        if (gotFrame != 0) {
            outputSampleCount = avresample_get_out_samples(resampleContext, frame->nb_samples);
            av_samples_alloc(&output, &outputLineSize, sampleFormat->channels, outputSampleCount,outputSampleFormat, 0);
            outputSampleCount = avresample_convert(resampleContext, &output, outputLineSize, outputSampleCount,frame->extended_data, frame->linesize[0], frame->nb_samples);
            ao_play(device, (char*)output, outputSampleCount * 4);
        }
        if (output != NULL) {
            free(output);
            output = NULL;
        }
    }

    free(sampleFormat);
    ao_close(device);
    ao_shutdown();
    avresample_free(&resampleContext);

    if (output != NULL) { free(output); }

    av_frame_free(&frame);
    av_free_packet(&packet);
}

void closeAudio(AudioFile *audioFile) {
    avcodec_free_context(&audioFile->codecContext);
    avformat_close_input(&audioFile->formatContext);
    free(audioFile);
}

int main(int argc, char *argv[]) {
    AudioFile *audioFile = loadAudio(argv[1]);
    playAudio(audioFile);
    closeAudio(audioFile);
}
