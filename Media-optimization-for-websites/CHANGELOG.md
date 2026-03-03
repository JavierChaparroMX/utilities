# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-03-03

### Initial Release

#### Features
- ✅ Batch image optimization (JPG, PNG, GIF → WebP + PNG fallback)
- ✅ Batch video optimization (MP4, MOV, AVI, WebM → MP4 + WebM)
- ✅ Configurable quality settings for images and videos
- ✅ Parallel processing with 4 worker threads (configurable)
- ✅ Auto-scaling of large videos (>1920px width)
- ✅ Mobile video variants (640px width)
- ✅ Dry-run mode for previewing conversions
- ✅ Resume capability for interrupted conversions
- ✅ Progress bar with real-time feedback
- ✅ Detailed logging to files
- ✅ JSON conversion report with metrics
- ✅ HTML visual report generation
- ✅ Apache .htaccess configuration generation
- ✅ Next.js image optimization config
- ✅ Responsive image srcset generator

#### Documentation
- ✅ Complete README with usage examples
- ✅ Quick Start guide (5-minute setup)
- ✅ Environment setup guide for Windows/macOS/Linux
- ✅ Complete documentation index
- ✅ Configuration examples and presets
- ✅ Troubleshooting section
- ✅ Integration guides (HTML, React, Next.js)

#### CLI Options
- `--source` - Source directory
- `--output` - Output directory
- `--image-quality` - JPEG/WebP quality (0-100)
- `--video-quality` - Video CRF (0-51)
- `--parallel` - Worker threads
- `--dry-run` - Preview mode
- `--continue` - Resume from checkpoint
- `--skip-images` - Skip image conversion
- `--skip-videos` - Skip video conversion
- `--no-backup` - Don't create PNG fallbacks
- `--verbose` - Detailed logging

#### NPM Scripts
- `npm run optimize` - Start optimization
- `npm run optimize:dry` - Preview conversions
- `npm run optimize:continue` - Resume
- `npm run optimize:images-only` - Images only
- `npm run optimize:videos-only` - Videos only

#### Utilities
- `generate-report-html.js` - Create HTML reports
- `generate-htaccess.js` - Apache configuration
- `generate-nextjs-config.js` - Next.js setup
- `generate-srcset.js` - Responsive image helpers

#### Reporting
- JSON report with detailed metrics per file
- HTML report with visual comparisons
- Detailed operation logs with timestamps
- Error tracking and recovery

---

## Planned Features (v1.1+)

- [ ] AVIF image format support
- [ ] HEIC/HEIF image support
- [ ] Batch quality presets from config file
- [ ] Real-time web dashboard for monitoring
- [ ] S3/Cloud storage upload integration
- [ ] Automatic CDN cache invalidation
- [ ] Image sprite/atlas generation
- [ ] WebP quality auto-detection
- [ ] Multi-language support
- [ ] Webhook notifications on completion
- [ ] Discord/Slack integration
- [ ] Scheduled batch processing
- [ ] GraphQL API for progress queries

---

## Known Limitations

- Animated GIFs flagged for video conversion (not auto-converted)
- Maximum video bitrate detection based on preset
- No lossless video codec support (H.265/HEVC)
- FFmpeg must be installed separately
- Windows requires admin for some operations

---

## Version History

| Version | Release Date | Status |
|---------|--------------|--------|
| 1.0.0 | 2026-03-03 | ✅ Current |
| 1.1.0 | TBD | Planned |
| 2.0.0 | TBD | Planned |

---

## Dependency Versions

- **Node.js:** 18.0.0+
- **sharp:** 0.33.0+ (image optimization)
- **fluent-ffmpeg:** 2.1.3+ (video processing)
- **cli-progress:** 3.12.0+ (progress bars)
- **chalk:** 5.3.0+ (colored output)
- **yargs:** 17.7.2+ (CLI argument parsing)
- **FFmpeg:** Latest (system dependency)

---

## Migration Guides

None yet for v1.0.0

---

## Contributors

- Initial release by Media Optimization Script Team

---

## Support

For issues or feature requests:
1. Check the logs in `public-optimized/conversion.log`
2. Review `DOCUMENTATION.md` for known issues
3. Try running with `--verbose` flag
4. Check FFmpeg is properly installed

---

## License

MIT - See LICENSE file for details

---

*Last updated: March 3, 2026*
