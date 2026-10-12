function main()
{
  const n_samples = 2049;
  const c_re_min = -2.05;
  const c_re_max = +0.55;
  const c_im_min = -1.30;
  const c_im_max = +1.30;
  let count = 0;
  const start = performance.now();
  for (let re_idx = 0; re_idx < n_samples; re_idx++)
  {
    const c_re = c_re_min + re_idx * ((c_re_max - c_re_min) / n_samples);
    for (let im_idx = 0; im_idx < n_samples; im_idx++)
    {
      const c_im = c_im_min + im_idx * ((c_im_max - c_im_min) / n_samples);
      let n_iter = 0;
      let z_re = 0.0;
      let z_im = 0.0;
      while (n_iter < 256 && z_re * z_re + z_im * z_im <= 4.0)
      {
        const tmp = z_re * z_re - z_im * z_im;
        z_im = 2.0 * z_re * z_im + c_im;
        z_re = tmp + c_re;
        n_iter++;
      }
      if (n_iter < 256)
      {
        count++;
      }
    }
  }
  const end = performance.now();
  const elapsedSeconds = (end - start) / 1e3;
  console.log(`${count} -- ${elapsedSeconds.toFixed(3)}`);
}
