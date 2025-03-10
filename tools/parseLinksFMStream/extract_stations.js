//useful dated: Mar 10 2025
//for use with fmstream.org only

//see https://fmstream.org/rsd.js
//thanks to Peer-Axel Kroeske <peeraxel@aol.com>

//thanks to gemini-2.0 for helping with converting
//from bitwise voodoo magic to http/https

function extractStationData() {
    // Get station names from HTML <div> elements inside <div id="tab">.
    const stationNameElements = document.querySelectorAll("#tab > div");
    const stationNames = Array.from(stationNameElements).map(div => {
        // Extract the name, removing the flag part (e.g., "MRC " in "MRC Station Name").
        let name = div.textContent;
        const spaceIndex = name.indexOf(" ");
        return (spaceIndex >= 0 ? name.substring(spaceIndex + 1) : name).trim();
    });

    const stations = {};
    for (let i = 0; i < data.length; i++) {
        const stationData = data[i];
        const stationName = stationNames[i];

        // "First in List" strategy: take the first stream, if it exists.
        if (stationData.length > 0 && stationData[0].length > 0) {
            const streamData = stationData[0];

            // --- Protocol Extraction (the "Voodoo") ---
            // The protocol (http, https, etc.) is encoded in the last three bits
            // of streamData[7].  `streamData[7] & 7` isolates these bits.
            // The result (0-7) is used as an index into the 'prtcl' array.
            const protocolIndex = streamData[7] & 7;
            const protocol = ['http', 'https', 'mms', 'mmsh', 'rtsp', 'rtmp'][protocolIndex];

            // Build the full URL.
            const streamUrl = protocol + "://" + streamData[0];
            stations[stationName] = streamUrl;
        }
    }

    return { stations: stations };
}

const stationJson = extractStationData();
console.log(JSON.stringify(stationJson, null, 2));
