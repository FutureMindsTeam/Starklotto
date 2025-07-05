import { useTheme } from "next-themes";
import { cn } from "~~/utils/cn";

interface GenericModalProps {
  children: React.ReactNode;
  className?: string;
  modalId: string;
  isOpen: boolean;
  onClose: () => void;
}

const GenericModal = ({
  children,
  className = "modal-box relative w-full max-w-[480px] p-6 bg-background border border-purple-500/20 rounded-2xl shadow-2xl",
  isOpen,
  onClose,
}: GenericModalProps) => {
  const { resolvedTheme } = useTheme();

  if (!isOpen) return null;

  return (
    <div
      className={cn(
        "fixed inset-0 flex items-center justify-center bg-black/50 backdrop-blur-sm transition-opacity duration-300",
        isOpen ? "opacity-100 visible" : "opacity-0 invisible",
      )}
      onClick={onClose} // Clicking outside closes modal
    >
      <div
        className={cn("w-full h-max max-h-[80vh]", className)}
        onClick={(e) => e.stopPropagation()} // Prevent closing when clicking inside
      >
        {children}
      </div>
    </div>
  );
};

export default GenericModal;
