import { useState, useEffect } from "react";
import { useTranslation } from "react-i18next";

export const useLanguage = () => {
  const { i18n } = useTranslation();
  const [currentLanguage, setCurrentLanguage] = useState(i18n.language);

  useEffect(() => {
    const handleLanguageChange = (lng: string) => {
      setCurrentLanguage(lng);
      // Update HTML lang attribute
      document.documentElement.lang = lng;
      // Store in localStorage
      localStorage.setItem("i18nextLng", lng);
    };

    // Set initial language
    const savedLanguage = localStorage.getItem("i18nextLng");
    if (savedLanguage && savedLanguage !== i18n.language) {
      i18n.changeLanguage(savedLanguage);
    }

    // Listen for language changes
    i18n.on("languageChanged", handleLanguageChange);

    return () => {
      i18n.off("languageChanged", handleLanguageChange);
    };
  }, [i18n]);

  const changeLanguage = (languageCode: string) => {
    i18n.changeLanguage(languageCode);
  };

  return {
    currentLanguage,
    changeLanguage,
    isEnglish: currentLanguage === "en",
    isSpanish: currentLanguage === "es",
    isFrench: currentLanguage === "fr",
    isPortuguese: currentLanguage === "pt",
  };
};
