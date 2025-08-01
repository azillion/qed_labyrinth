export function BlogImage({ src, alt, className = "" }) {
  return (
    <figure className={`my-8 ${className}`}>
      <div className="w-full max-w-2xl mx-auto rounded-lg overflow-hidden border border-stone-700/30">
        <img
          src={src}
          alt={alt}
          className="w-full h-auto object-contain"
          loading="lazy"
        />
      </div>
      {alt && (
        <figcaption className="text-center text-stone-400 text-sm mt-2 font-serif">
          {alt}
        </figcaption>
      )}
    </figure>
  );
} 