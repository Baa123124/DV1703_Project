(() => {
  const ISO_DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
  const PREV_ARROW = [
    '<svg aria-hidden="true" viewBox="0 0 24 24" class="h-4 w-4">',
    '<path d="M14.7 5.3a1 1 0 0 1 0 1.4L10.41 11l4.3 4.3a1 1 0 1 1-1.42 1.4l-5-5a1 1 0 0 1 0-1.4l5-5a1 1 0 0 1 1.41 0Z" fill="currentColor"/>',
    "</svg>",
  ].join("");
  const NEXT_ARROW = [
    '<svg aria-hidden="true" viewBox="0 0 24 24" class="h-4 w-4">',
    '<path d="M9.29 5.29a1 1 0 0 1 1.41 0l5 5a1 1 0 0 1 0 1.42l-5 5a1 1 0 1 1-1.41-1.42L13.58 12 9.3 7.71a1 1 0 0 1 0-1.42Z" fill="currentColor"/>',
    "</svg>",
  ].join("");

  const isIsoDate = (value) => ISO_DATE_PATTERN.test((value || "").trim());
  const resolveFlatpickrLocale = (localeName) => {
    if (!window.flatpickr || !localeName) {
      return {
        firstDayOfWeek: 1,
      };
    }

    return window.flatpickr.l10ns?.[localeName] || localeName;
  };

  const initThemedDatePicker = (input, options = {}) => {
    if (!window.flatpickr) {
      return null;
    }

    input.readOnly = true;
    input.setAttribute("aria-readonly", "true");

    const { localeName, ...flatpickrOptions } = options;
    const onReadyHook = options.onReady;
    const onChangeHook = options.onChange;
    const onCloseHook = options.onClose;

    return window.flatpickr(input, {
      allowInput: false,
      dateFormat: "Y-m-d",
      disableMobile: true,
      monthSelectorType: "static",
      locale: resolveFlatpickrLocale(localeName),
      nextArrow: NEXT_ARROW,
      prevArrow: PREV_ARROW,
      ...flatpickrOptions,
      onReady(selectedDates, dateText, instance) {
        if (typeof onReadyHook === "function") {
          onReadyHook(selectedDates, dateText, instance);
        }
      },
      onChange(selectedDates, dateText, instance) {
        if (typeof onChangeHook === "function") {
          onChangeHook(selectedDates, dateText, instance);
        }
      },
      onClose(selectedDates, dateText, instance) {
        if (typeof onCloseHook === "function") {
          onCloseHook(selectedDates, dateText, instance);
        }
      },
    });
  };

  const setInputValue = (input, picker, value) => {
    if (picker) {
      picker.setDate(value || null, false, "Y-m-d");
      return;
    }

    input.value = value || "";
  };

  const initDateRange = (container) => {
    const startInput = container.querySelector("[data-date-range-start]");
    const endInput = container.querySelector("[data-date-range-end]");

    if (!startInput || !endInput) {
      return;
    }

    const shouldUseThemedCalendar = container.dataset.dateRangeCalendar === "themed" && Boolean(window.flatpickr);
    const localeName = container.dataset.dateRangeLocale || "";

    let startPicker = null;
    let endPicker = null;

    const updateEndConstraints = () => {
      const startValue = isIsoDate(startInput.value) ? startInput.value : "";
      endInput.min = startValue || "";

      if (endPicker) {
        endPicker.set("minDate", startValue || null);
      }
    };

    const syncEndDate = () => {
      const startValue = isIsoDate(startInput.value) ? startInput.value : "";
      const endValue = isIsoDate(endInput.value) ? endInput.value : "";

      updateEndConstraints();

      if (!startValue) {
        return;
      }

      if (!endValue || endValue < startValue) {
        setInputValue(endInput, endPicker, startValue);
      }
    };

    if (shouldUseThemedCalendar) {
      startPicker = initThemedDatePicker(startInput, {
        defaultDate: isIsoDate(startInput.value) ? startInput.value : null,
        localeName,
        onChange() {
          syncEndDate();
        },
        onClose() {
          syncEndDate();
        },
      });

      endPicker = initThemedDatePicker(endInput, {
        defaultDate: isIsoDate(endInput.value) ? endInput.value : null,
        minDate: isIsoDate(startInput.value) ? startInput.value : null,
        localeName,
        onChange() {
          updateEndConstraints();
        },
        onClose() {
          updateEndConstraints();
        },
      });
    }

    startInput.addEventListener("change", syncEndDate);
    startInput.addEventListener("input", syncEndDate);
    endInput.addEventListener("change", updateEndConstraints);
    endInput.addEventListener("input", updateEndConstraints);

    syncEndDate();
  };

  document.querySelectorAll("[data-date-range]").forEach(initDateRange);
})();
