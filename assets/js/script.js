(function () {
  "use strict";

  var header = document.querySelector(".site-header");
  var navbar = document.getElementById("navbar");
  var navToggle = document.getElementById("navToggle");
  var mobileMenu = document.getElementById("mobileMenu");
  var navLinks = document.querySelectorAll(".nav-link");
  var sections = document.querySelectorAll("main section[id]");

  /* Scrolled navbar state */
  function onScroll() {
    if (window.scrollY > 12) {
      navbar.classList.add("is-scrolled");
    } else {
      navbar.classList.remove("is-scrolled");
    }
  }
  document.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  /* Mobile menu toggle */
  function closeMenu() {
    navToggle.classList.remove("is-open");
    navToggle.setAttribute("aria-expanded", "false");
    mobileMenu.classList.remove("is-open");
  }

  navToggle.addEventListener("click", function () {
    var willOpen = !mobileMenu.classList.contains("is-open");
    navToggle.classList.toggle("is-open", willOpen);
    navToggle.setAttribute("aria-expanded", String(willOpen));
    mobileMenu.classList.toggle("is-open", willOpen);
  });

  mobileMenu.querySelectorAll("a").forEach(function (link) {
    link.addEventListener("click", closeMenu);
  });

  /* Scroll-spy: highlight active nav link */
  if ("IntersectionObserver" in window && sections.length) {
    var spy = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          var id = entry.target.getAttribute("id");
          navLinks.forEach(function (link) {
            link.classList.toggle("active", link.getAttribute("href") === "#" + id);
          });
        });
      },
      { rootMargin: "-45% 0px -50% 0px", threshold: 0 }
    );
    sections.forEach(function (section) { spy.observe(section); });
  }

  /* Scroll-reveal animations: replays every time an element crosses into
     or out of view, rather than firing once and staying revealed. Each
     element's delay is based on its position among siblings that share
     the same parent, so cards in the same row/grid cascade in together
     instead of all inheriting one page-wide stagger counter. */
  var revealEls = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window && revealEls.length) {
    var parentGroups = new Map();
    revealEls.forEach(function (el) {
      var parent = el.parentElement;
      if (!parentGroups.has(parent)) parentGroups.set(parent, []);
      parentGroups.get(parent).push(el);
    });
    parentGroups.forEach(function (siblings) {
      siblings.forEach(function (el, i) {
        el.style.transitionDelay = Math.min(i, 5) * 90 + "ms";
      });
    });

    var reveal = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          entry.target.classList.toggle("in-view", entry.isIntersecting);
        });
      },
      { threshold: 0.08, rootMargin: "0px 0px -10% 0px" }
    );
    revealEls.forEach(function (el) { reveal.observe(el); });

    /* Safety net: a fast fling or an instant/jumped scroll can move the
       page far enough in a single frame that an element's intersection
       state skips straight over "visible" (or back out of it) and the
       observer never reports the change. Sweep on scroll and correct
       anything whose class doesn't match its actual position. */
    var sweep = function () {
      var vh = window.innerHeight;
      revealEls.forEach(function (el) {
        var rect = el.getBoundingClientRect();
        var shouldShow = rect.top < vh * 0.92 && rect.bottom > vh * 0.02;
        if (shouldShow !== el.classList.contains("in-view")) {
          el.classList.toggle("in-view", shouldShow);
        }
      });
    };
    document.addEventListener("scroll", sweep, { passive: true });
    sweep();
  } else {
    revealEls.forEach(function (el) { el.classList.add("in-view"); });
  }

  /* Stat counters: count up from 0 to their target once, starting as the
     stats strip crosses the vertical middle of the viewport, then settle
     on the final value — a number that reset and replayed every time you
     scrolled past it would read as broken rather than delightful. */
  var statNums = document.querySelectorAll(".stat-num[data-count-to]");
  if (statNums.length) {
    var animateCount = function (el, delay) {
      var target = parseFloat(el.getAttribute("data-count-to"));
      var suffix = el.getAttribute("data-count-suffix") || "";
      var duration = 1300;
      var easeOutCubic = function (t) { return 1 - Math.pow(1 - t, 3); };
      var start = null;
      var step = function (ts) {
        if (start === null) start = ts;
        var elapsed = ts - start;
        if (elapsed < delay) {
          requestAnimationFrame(step);
          return;
        }
        var progress = Math.min((elapsed - delay) / duration, 1);
        var value = Math.round(target * easeOutCubic(progress));
        el.textContent = value + suffix;
        if (progress < 1) requestAnimationFrame(step);
      };
      requestAnimationFrame(step);
    };

    if ("IntersectionObserver" in window) {
      var statsStrip = document.querySelector(".stats-strip");
      var counted = false;
      var countObserver = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (entry.isIntersecting && !counted) {
              counted = true;
              statNums.forEach(function (el, i) { animateCount(el, i * 90); });
              countObserver.disconnect();
            }
          });
        },
        { rootMargin: "-45% 0px -45% 0px", threshold: 0 }
      );
      countObserver.observe(statsStrip || statNums[0]);
    } else {
      statNums.forEach(function (el) {
        el.textContent = el.getAttribute("data-count-to") + (el.getAttribute("data-count-suffix") || "");
      });
    }
  }

  /* Design Gallery: 3D card fan. The 6 cards are purely decorative (no
     links) and keep their fixed positions around the ring (set in CSS
     via --gi); the ring itself spins as one rigid group around its
     shared center point, driven by three inputs that add together:
       1. Scroll (Y axis): how far the stage has travelled through the
          viewport maps to a rotation angle, so scrolling past this
          section spins it.
       2. Drag (Y axis): click-and-hold plus horizontal mouse movement
          adds a manual spin on top, released when the mouse comes up.
       3. Cursor hover (X and Z axes): passively follows the cursor
          position over the stage with a low sensitivity, so it reads
          as a gentle tilt rather than the primary motion. */
  var galleryStage = document.getElementById("galleryStage");
  var galleryRing = document.getElementById("galleryRing");
  if (galleryStage && galleryRing) {
    var IDLE_TILT = 9;
    var scrollRotation = 0;
    var dragRotation = 0;
    var cursorTiltX = 0;
    var cursorTiltZ = 0;
    var isDragging = false;
    var dragStartX = 0;
    var dragStartRotation = 0;

    var applyRotation = function () {
      galleryRing.style.transform =
        "scale(0.5) " +
        "rotateX(" + (IDLE_TILT + cursorTiltX) + "deg) " +
        "rotateY(" + (scrollRotation + dragRotation) + "deg) " +
        "rotateZ(" + cursorTiltZ + "deg)";
    };

    var updateScrollRotation = function () {
      var rect = galleryStage.getBoundingClientRect();
      var vh = window.innerHeight;
      var total = rect.height + vh;
      var progress = (vh - rect.top) / total;
      progress = Math.min(Math.max(progress, 0), 1);
      scrollRotation = progress * 220;
      applyRotation();
    };
    document.addEventListener("scroll", updateScrollRotation, { passive: true });
    updateScrollRotation();

    galleryStage.addEventListener("mousemove", function (e) {
      var rect = galleryStage.getBoundingClientRect();
      var px = (e.clientX - rect.left) / rect.width - 0.5;
      var py = (e.clientY - rect.top) / rect.height - 0.5;
      cursorTiltX = -py * 18;
      cursorTiltZ = px * 8;
      applyRotation();
    });
    var endDrag = function () {
      if (!isDragging) return;
      isDragging = false;
      galleryStage.classList.remove("is-dragging");
    };

    galleryStage.addEventListener("mousedown", function (e) {
      isDragging = true;
      dragStartX = e.clientX;
      dragStartRotation = dragRotation;
      galleryStage.classList.add("is-dragging");
      e.preventDefault();
    });
    window.addEventListener("mousemove", function (e) {
      if (!isDragging) return;
      var dx = e.clientX - dragStartX;
      dragRotation = dragStartRotation + dx * 0.35;
      applyRotation();
    });
    window.addEventListener("mouseup", endDrag);
    galleryStage.addEventListener("mouseleave", endDrag);
  }
  var galleryMobileRow = document.getElementById("galleryMobileRow");
  if (galleryMobileRow && galleryRing) {
    galleryRing.querySelectorAll(".gallery-card").forEach(function (card) {
      var clone = card.cloneNode(true);
      clone.style.transform = "";
      galleryMobileRow.appendChild(clone);
    });
  }

  /* Org chart connector spine: align the vertical dashed line to the
     exact vertical center of the first and last row's branch point,
     instead of a rough percentage guess that overshoots past the
     horizontal connectors and leaves stray dangling line ends. */
  var orgRows = document.querySelector(".org-rows");
  if (orgRows) {
    var alignOrgSpine = function () {
      var rows = Array.prototype.slice.call(orgRows.querySelectorAll(".org-row"));
      if (rows.length < 2) return;
      var containerRect = orgRows.getBoundingClientRect();
      var firstRect = rows[0].getBoundingClientRect();
      var lastRect = rows[rows.length - 1].getBoundingClientRect();
      var topOffset = (firstRect.top + firstRect.height / 2) - containerRect.top;
      var bottomOffset = containerRect.bottom - (lastRect.top + lastRect.height / 2);
      orgRows.style.setProperty("--spine-top", topOffset + "px");
      orgRows.style.setProperty("--spine-bottom", bottomOffset + "px");
    };
    alignOrgSpine();
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(alignOrgSpine);
    window.addEventListener("load", alignOrgSpine);
    window.addEventListener("resize", alignOrgSpine);
  }

  /* Task flow spine: align the vertical dashed connector to run exactly
     from the first step's dot to the last step's dot, mirroring the
     org-chart spine above. */
  var tfDiagram = document.querySelector(".tf-diagram");
  if (tfDiagram) {
    var alignTfSpine = function () {
      var labels = Array.prototype.slice.call(tfDiagram.querySelectorAll(".tf-label"));
      if (labels.length < 2) return;
      var containerRect = tfDiagram.getBoundingClientRect();
      var firstRect = labels[0].getBoundingClientRect();
      var lastRect = labels[labels.length - 1].getBoundingClientRect();
      var topOffset = (firstRect.top + firstRect.height / 2) - containerRect.top;
      var bottomOffset = containerRect.bottom - (lastRect.top + lastRect.height / 2);
      tfDiagram.style.setProperty("--tf-spine-top", topOffset + "px");
      tfDiagram.style.setProperty("--tf-spine-bottom", bottomOffset + "px");
    };
    alignTfSpine();
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(alignTfSpine);
    window.addEventListener("load", alignTfSpine);
    window.addEventListener("resize", alignTfSpine);
  }

  /* Live prototype embeds: the embedded page is a fixed 1440px-wide app
     UI, so we scale the iframe down to fit whatever width its container
     actually renders at, keeping the design pixel-accurate at any size. */
  var protoEmbeds = document.querySelectorAll("[data-prototype-embed]");
  if (protoEmbeds.length) {
    var scaleProtoEmbeds = function () {
      protoEmbeds.forEach(function (wrap) {
        var iframe = wrap.querySelector("iframe");
        if (!iframe) return;
        var scale = wrap.clientWidth / 1440;
        iframe.style.transform = "scale(" + scale + ")";
      });
    };
    scaleProtoEmbeds();
    window.addEventListener("resize", scaleProtoEmbeds);
  }

  /* Ambient parallax: the fixed background glows drift at different
     speeds (and one in the opposite direction) as the page scrolls,
     giving the whole site a sense of depth behind the content. */
  var glowTop = document.querySelector(".glow--top");
  var glowBottom = document.querySelector(".glow--bottom");
  if ((glowTop || glowBottom) && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    var parallaxTicking = false;
    var updateParallax = function () {
      var y = window.scrollY;
      var topOffset = Math.min(y * 0.35, 320);
      var bottomOffset = Math.max(y * -0.28, -280);
      document.documentElement.style.setProperty("--parallax-top", topOffset.toFixed(1) + "px");
      document.documentElement.style.setProperty("--parallax-bottom", bottomOffset.toFixed(1) + "px");
      parallaxTicking = false;
    };
    document.addEventListener("scroll", function () {
      if (!parallaxTicking) {
        requestAnimationFrame(updateParallax);
        parallaxTicking = true;
      }
    }, { passive: true });
    updateParallax();
  }

  /* Subtle cursor-reactive glow in hero */
  var hero = document.getElementById("hero");
  if (hero && window.matchMedia("(hover: hover)").matches) {
    hero.addEventListener("pointermove", function (e) {
      var rect = hero.getBoundingClientRect();
      var x = ((e.clientX - rect.left) / rect.width) * 100;
      var y = ((e.clientY - rect.top) / rect.height) * 100;
      hero.style.setProperty("--mx", x + "%");
      hero.style.setProperty("--my", y + "%");
    });
  }

  /* Featured project screenshot rotators: several comparison variants,
     each pushing/fading/zooming/wiping/flipping through a set of real
     product screens. Each pauses while hovered and pulses a tiny
     particle-burst glow behind the frame on every transition. */
  var ROTATE_MS = 3800;
  var TRANSITION_MS = 900;

  function buildGlowParticles(glowEl) {
    var count = 26;
    for (var i = 0; i < count; i++) {
      var span = document.createElement("span");
      span.className = "glow-particle";
      var angle = (360 / count) * i + (Math.random() * 10 - 5);
      var distance = 46 + Math.random() * 30;
      var delay = Math.random() * 0.15;
      span.style.setProperty("--angle", angle + "deg");
      span.style.setProperty("--distance", distance + "px");
      span.style.setProperty("--delay", delay + "s");
      glowEl.appendChild(span);
    }
  }

  document.querySelectorAll("[data-rotator]").forEach(function (rotator) {
    var frames = Array.prototype.slice.call(rotator.querySelectorAll(".visual-frame"));
    var reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    var wrap = rotator.closest(".featured-visual-wrap");
    var glow = wrap ? wrap.querySelector("[data-glow]") : null;
    var glowTimer = null;

    if (glow) buildGlowParticles(glow);
    if (frames.length < 2 || reducedMotion) return;

    var current = 0;
    var timer = null;

    var advance = function () {
      var outgoing = frames[current];
      current = (current + 1) % frames.length;
      var incoming = frames[current];

      outgoing.classList.remove("is-active");
      outgoing.classList.add("is-leaving");
      incoming.classList.add("is-active");

      var outgoingVideo = outgoing.querySelector("video");
      if (outgoingVideo) outgoingVideo.pause();
      var incomingVideo = incoming.querySelector("video");
      if (incomingVideo) {
        incomingVideo.currentTime = 0;
        incomingVideo.play().catch(function () {});
      }

      setTimeout(function () {
        outgoing.style.transition = "none";
        outgoing.classList.remove("is-leaving");
        void outgoing.offsetWidth; /* force reflow before re-enabling */
        outgoing.style.transition = "";
      }, TRANSITION_MS);

      if (glow) {
        clearTimeout(glowTimer);
        glow.classList.remove("is-pulsing");
        void glow.offsetWidth; /* restart the particle-burst animation */
        glow.classList.add("is-pulsing");
        glowTimer = setTimeout(function () { glow.classList.remove("is-pulsing"); }, TRANSITION_MS + 100);
      }
    };

    var intervalMs = parseInt(rotator.dataset.rotateMs, 10) || ROTATE_MS;

    var start = function () {
      if (timer) return;
      var activeVideo = frames[current].querySelector("video");
      if (activeVideo) activeVideo.play().catch(function () {});
      timer = setInterval(advance, intervalMs);
    };
    var stop = function () {
      clearInterval(timer);
      timer = null;
      var activeVideo = frames[current].querySelector("video");
      if (activeVideo) activeVideo.pause();
    };

    start();
    rotator.addEventListener("mouseenter", stop);
    rotator.addEventListener("mouseleave", start);
    rotator.addEventListener("touchstart", stop, { passive: true });
    rotator.addEventListener("touchend", start, { passive: true });
  });

  /* Hero headline word rotator: "effortless" / "intuitive" / "delightful"
     tumble past each other on the horizontal axis, blurring and briefly
     overlapping mid-transition — driven by simple class toggles rather
     than a computed 3D drum, so it's robust and easy to verify. */
  var wordCube = document.getElementById("wordRotator");
  if (wordCube) {
    var faces = Array.prototype.slice.call(wordCube.querySelectorAll(".word-face"));

    if (faces.length > 1) {
      var layoutWordCube = function () {
        var maxWidth = 0;
        faces.forEach(function (f) {
          maxWidth = Math.max(maxWidth, f.getBoundingClientRect().width);
        });
        wordCube.style.width = Math.ceil(maxWidth) + "px";
      };

      layoutWordCube();
      if (document.fonts && document.fonts.ready) {
        document.fonts.ready.then(layoutWordCube);
      }
      window.addEventListener("resize", layoutWordCube);

      faces[0].classList.add("is-active");

      if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
        var wordCurrent = 0;
        setInterval(function () {
          var outgoing = faces[wordCurrent];
          wordCurrent = (wordCurrent + 1) % faces.length;
          var incoming = faces[wordCurrent];

          outgoing.classList.remove("is-active");
          outgoing.classList.add("is-leaving");
          incoming.classList.add("is-active");

          setTimeout(function () {
            outgoing.classList.remove("is-leaving");
          }, 600);
        }, 2600);
      }
    }
  }
})();
