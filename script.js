// Function to apply animations and effects
function applyAnimations() {
  const elements = document.querySelectorAll(
    ".hero, .features h2, .installation h2, .demo h2, .documentation h2, .contributing h2, .credits h2, .license h2"
  );

  elements.forEach((element, index) => {
    element.style.opacity = "0";
    element.style.transform = "translateY(20px)";
    setTimeout(() => {
      element.style.transition = "opacity 1s ease, transform 1s ease";
      element.style.opacity = "1";
      element.style.transform = "translateY(0)";
    }, index * 200);
  });

  // Animate feature cards and installation boxes on scroll
  const animatedElements = document.querySelectorAll(
    ".feature-card, .instructions pre"
  );
  animateOnScroll(animatedElements);
}

// Function to apply the animation based on calculated progress
function animateOnScroll(elements) {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('in-viewport');
        observer.unobserve(entry.target);
      }
    });
  }, {
    threshold: 0, // Trigger even if a small part intersects
  });

  elements.forEach((element) => {
    observer.observe(element);
  });
}

// Apply animations on page load
window.addEventListener("load", applyAnimations);