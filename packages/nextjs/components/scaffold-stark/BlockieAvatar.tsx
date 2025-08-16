"use client";

import { useState } from "react";
import { blo } from "blo";
import { User } from "lucide-react";

interface BlockieAvatarProps {
  address: string;
  ensImage?: string | null;
  size: number;
}

// Custom Avatar for RainbowKit
export const BlockieAvatar = ({
  address,
  ensImage,
  size,
}: BlockieAvatarProps) => {
  const [imageError, setImageError] = useState(false);
  const [bloError, setBloError] = useState(false);

  // Función para generar avatar blo de forma segura
  const generateBloAvatar = () => {
    try {
      return blo(address as `0x${string}`);
    } catch (error) {
      console.warn("Error generating blo avatar:", error);
      setBloError(true);
      return null;
    }
  };

  // Si hay errores tanto en ensImage como en blo, mostrar icono de usuario
  if ((imageError || !ensImage) && (bloError || !address)) {
    return (
      <div 
        className="rounded-full bg-gradient-to-r from-[#00FFA3] to-[#00E5FF] flex items-center justify-center"
        style={{ width: size, height: size }}
      >
        <User 
          className="text-black" 
          size={size * 0.6} 
        />
      </div>
    );
  }

  const avatarSrc = ensImage || generateBloAvatar();

  if (!avatarSrc) {
    return (
      <div 
        className="rounded-full bg-gradient-to-r from-[#00FFA3] to-[#00E5FF] flex items-center justify-center"
        style={{ width: size, height: size }}
      >
        <User 
          className="text-black" 
          size={size * 0.6} 
        />
      </div>
    );
  }

  return (
    // Don't want to use nextJS Image here (and adding remote patterns for the URL)
    // eslint-disable-next-line @next/next/no-img-element
    <img
      className="rounded-full"
      src={avatarSrc}
      width={size}
      height={size}
      alt={`${address} avatar`}
      onError={() => {
        setImageError(true);
        if (!ensImage) {
          setBloError(true);
        }
      }}
      onLoad={() => {
        setImageError(false);
        setBloError(false);
      }}
    />
  );
};
