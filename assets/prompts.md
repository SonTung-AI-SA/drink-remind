# Prompts và nguồn gốc

Ngày tạo: 28/10/2026. Phương thức: công cụ imagegen tích hợp, không dùng API/CLI và không dùng ảnh tham chiếu bên ngoài. Mỗi ảnh là một lần gọi riêng; atlas là một ảnh chứa nhiều ô. Ảnh gốc được giữ nguyên và sao chép vào project.

## Style chung — nối sau tiền tố mỗi prompt

```text
Original cozy 2D mobile game art for a water-drinking virtual-pet app, Little Island. Soft matte pastel colors, clean rounded silhouettes, gentle hand-painted vector-like shading, minimal detail readable at 80px, warm sand, sage foliage and turquoise water. Three-quarter slightly elevated view, lighting upper left. No existing IP, no text, letters, labels, logos, watermark, UI, or fake checkerboard.
```

Mỗi prompt đầy đủ là **tiền tố + style chung + phần yêu cầu** dưới đây.

## island/island-base.png

Tiền tố:

```text
Use case: stylized-concept. Asset type: transparent island terrain layer.
```

Phần yêu cầu:

```text
One isolated small oval island with grassy sage-green top, warm sandy exposed shoreline edge, shallow small turquoise pond in the front-left. Leave center-right clear as pet placement. No trees, house, flowers, animals, sky or sea background; terrain and pond only. Entire island fully visible with generous transparent padding on all sides, landscape composition. Genuine transparent background.
```

Tham số `transparent_background`: true.

## pets/mochi-states.png

Tiền tố:

```text
Use case: stylized-concept. Asset type: character state atlas, transparent PNG.
```

Phần yêu cầu:

```text
Create ONE sprite atlas in EXACTLY 3 equal columns and 2 equal rows. Six full-body poses of exactly the SAME original kitten Mochi: round cream-apricot short fur, little darker triangular ears, tiny dark brown oval eyes, peach cheeks, green collar and small golden bell, plump body short legs curled tail. Top-left idle sitting; top-middle eyes closed sleeping curled; top-right happy smile standing with both paws raised. Bottom-left eating head lowered toward a small terracotta food bowl; bottom-middle playful paw raised; bottom-right happy small jump. Each pose centered in its own cell with at least 18% blank padding, equal character scale and feet alignment within each cell where possible, no cell borders, no other elements. Transparent background throughout. No shadows extending between cells.
```

Tham số `transparent_background`: true.

## decorations/island-props.png

Tiền tố:

```text
Use case: stylized-concept. Asset type: decoration atlas, transparent PNG.
```

Phần yêu cầu:

```text
ONE prop atlas EXACTLY 3 equal columns and 2 equal rows, isolated objects centered with 20% clear padding in each cell. Top-left one round-canopy sage tree with short warm wood trunk; top-middle one tiny cream cottage with terracotta roof and round doorway; top-right small terracotta pet food bowl. Bottom-left single small clump of three warm yellow daisies with green stems; bottom-middle small two-leaf green seedling in soil; bottom-right two smooth shoreline rocks together with one grass tuft. Consistent scale within item category, no terrain under items except tiny seedling soil, no labels or grid lines, transparent background.
```

Tham số `transparent_background`: true.

## backgrounds/sky-sea.png

Tiền tố:

```text
Use case: illustration-story. Asset type: background layer landscape.
```

Phần yêu cầu:

```text
Quiet empty landscape backdrop only: pale powder blue sky occupying upper 65%, calm pastel turquoise sea occupying bottom 35%, very soft horizon, small soft cream clouds near upper left and upper right, warm small sun at upper-right. Center area spacious and empty for an island and pet to be composited later. No islands, land, buildings, pets or plants. Clean edge to edge opaque rectangular landscape image.
```

Tham số `transparent_background`: false.

## Icon

SVG tự viết cho project, không dùng imagegen, không sao chép bộ icon bên thứ ba. Cùng hệ viewBox 28 × 28, stroke 1.8, round caps/joins, màu currentColor. Các hình: đảo và cây, biểu đồ hành trình, người dùng, giọt nước, chuông, dấu cộng.
