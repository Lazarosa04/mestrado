import Foundation

let n_samples = 2049
let c_re_min = -2.05
let c_re_max = +0.55
let c_im_min = -1.30
let c_im_max = +1.30
var count = 0

let startTime = Foundation.ProcessInfo.processInfo.systemUptime
for re_idx in 0..<n_samples {
  let c_re = c_re_min + Double(re_idx) * ((c_re_max - c_re_min) / Double(n_samples))
  for im_idx in 0..<n_samples {
      let c_im = c_im_min + Double(im_idx) * ((c_im_max - c_im_min) / Double(n_samples))
      var n_iter = 0
      var z_re = 0.0
      var z_im = 0.0
      while n_iter < 256 && z_re * z_re + z_im * z_im <= 4.0 {
          let tmp = z_re * z_re - z_im * z_im
          z_im = 2.0 * z_re * z_im + c_im
          z_re = tmp + c_re
          n_iter += 1
      }
      if n_iter < 256 {
          count += 1
      }
  }
}
let elapsedTime = Foundation.ProcessInfo.processInfo.systemUptime - startTime

print(String(format: "%d -- %7.3f", count, elapsedTime))
