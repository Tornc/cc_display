Experimenting with multi-colour subpixel rendering. See the `lib` folder for the meat and potatoes.

> [!NOTE]
> For converting a texture to subpixels, I used exerro's method of getting the correct character. See: https://github.com/exerro/ccgl/blob/master/src/functions/texture_subpixel_convert.lua. Hopefully it's not seen as plagiarism 😓.

### Interactive physics simulation

![physics](./docs/physics.gif)

### Drawing functions

![shapes](./docs/shapes.png)

| Type              | ms (avg) |
| ----------------- | -------- |
| Rectangle Fill    | 0.175    |
| Triangle Fill     | 0.201    |
| Rectangle texture | 0.396    |
| Triangle texture  | 1.757    |

N = 1000. Rectangle area: 8729 pixels, triangle area: 8641.5 pixels. The triangle with texture is extremely slow relative to all the other functions.

### Flappy bird

![flappy_bird](./docs/flappy_bird.gif)

### Media display

![image](./docs/image.png)
![video](./docs/video.gif)

### TODO

- [ ] Speed up and improve `blit_triangle(...)`
