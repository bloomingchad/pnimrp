// Function to apply initial fade-in animations and scroll-triggered animations
function applyAnimations() {
  // Initial fade-in for hero and section headings
  const initialFadeInElements = document.querySelectorAll(
    ".hero, .features h2, .installation h2, .demo h2, .documentation h2, .contributing h2, .credits h2, .license h2"
  );

  initialFadeInElements.forEach((element, index) => {
    element.classList.add('fade-in-element'); // Add initial class
    setTimeout(() => {
      element.classList.add('visible'); // Add class to trigger transition
    }, index * 200);
  });

  // Animate feature cards and installation boxes on scroll
  const animatedElements = document.querySelectorAll(
    ".feature-card, .instructions pre"
  );
  animateOnScroll(animatedElements);
}

// Function to apply scroll-triggered animations using Intersection Observer
function animateOnScroll(elements) {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('in-viewport');
        observer.unobserve(entry.target); // Stop observing once in view
      }
    });
  }, {
    rootMargin: '-50px 0px', // Trigger animation 50px before element enters viewport
    threshold: 0.1,        // Trigger when 10% of the element is visible
  });

  elements.forEach((element) => {
    observer.observe(element);
  });
}

// Apply animations when the DOM is fully loaded
document.addEventListener("DOMContentLoaded", applyAnimations);