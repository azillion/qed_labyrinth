export function BlogImage({ src, alt, className = "" }) {
  return (
    <figure className={`my-8 ${className}`}>
      <div className="w-full rounded-lg overflow-hidden border border-stone-700/30">
        <img
          src={src}
          alt={alt}
          className="w-full h-auto max-h-96 object-cover"
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