// Function to apply animations and effects
function applyAnimations() {
  const elements = document.querySelectorAll('.hero, .features h2, .installation h2, .demo h2, .documentation h2, .contributing h2, .credits h2, .license h2');

  elements.forEach((element, index) => {
      element.style.opacity = '0';
      element.style.transform = 'translateY(20px)';
      setTimeout(() => {
          element.style.transition = 'opacity 1s ease, transform 1s ease';
          element.style.opacity = '1';
          element.style.transform = 'translateY(0)';
      }, index * 200);
  });
}

// Apply animations on page load
window.addEventListener('load', applyAnimations);