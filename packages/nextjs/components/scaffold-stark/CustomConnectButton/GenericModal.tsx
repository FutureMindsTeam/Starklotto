import { useTheme } from "next-themes";

const GenericModal = ({
  children,
  className = "bg-modal rounded-[8px] border flex flex-col gap-3 justify-around relative w-[90%] max-w-[480px] p-6",
  modalId,
  onClose,
}: {
  children: React.ReactNode;
  className?: string;
  modalId: string;
  onClose: () => void;
}) => {
  const { resolvedTheme } = useTheme();
  const isDarkMode = resolvedTheme === "dark";

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center">
      <div
        className="fixed inset-0 bg-black/50 backdrop-blur-sm transition-opacity"
        onClick={onClose}
      />
      <div className="relative z-[101] animate-modalFadeIn self-start mt-20">
        <div className={`${className} shadow-xl`}>
          {/* dummy input to capture event onclick on modal box */}
          <input className="h-0 w-0 absolute top-0 left-0" />
          {children}
        </div>
      </div>
    </div>
  );
};

export default GenericModal;
