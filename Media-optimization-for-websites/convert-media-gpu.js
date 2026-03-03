#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import sharp from 'sharp';
import ffmpeg from 'fluent-ffmpeg';
import cliProgress from 'cli-progress';
import chalk from 'chalk';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import { Worker } from 'worker_threads';

// Setup dirname for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ============================================
// CONFIGURATION & CONSTANTS - GPU OPTIMIZED
// ============================================

const DEFAULT_CONFIG = {
  source: './public',
  output: './public-optimized',
  imageQuality: 80,
  videoQuality: 28,
  parallel: 4,
  minImageSize: 100 * 1024, // 100KB in bytes
  minVideoSize: 2 * 1024 * 1024, // 2MB in bytes
  imageFormats: {
    source: ['.jpg', '.jpeg', '.png', '.gif'],
    target: ['.webp', '.png'] // WebP primary, PNG fallback
  },
  videoFormats: {
    source: ['.mp4', '.mov', '.avi', '.webm'],
    target: ['.mp4', '.webm']
  },
  videoDirs: {
    original: 'videos-optimized',
    mobile: 'videos-optimized/mobile'
  },
  imageDirs: {
    original: 'images-optimized'
  },
  // GPU-specific settings
  gpu: {
    enabled: true,
    vendor: 'AMD', // AMD Radeon detection
    encoder: 'hevc_amf', // AMD HEVC encoder
    enableHardwareDecoding: true
  }
};

// ============================================
// LOGGER
// ============================================

class Logger {
  constructor(filePath) {
    this.filePath = filePath;
    this.logs = [];
    this.ensureLogFile();
  }

  ensureLogFile() {
    const dir = path.dirname(this.filePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    if (!fs.existsSync(this.filePath)) {
      fs.writeFileSync(this.filePath, '');
    }
  }

  log(level, message, data = null) {
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] [${level}] ${message}`;
    const fullEntry = data ? `${logEntry} ${JSON.stringify(data)}` : logEntry;

    this.logs.push(fullEntry);
    fs.appendFileSync(this.filePath, fullEntry + '\n');

    // Console output with colors
    switch (level) {
      case 'INFO':
        console.log(chalk.blue(`ℹ ${message}`));
        break;
      case 'SUCCESS':
        console.log(chalk.green(`✓ ${message}`));
        break;
      case 'WARN':
        console.log(chalk.yellow(`⚠ ${message}`));
        break;
      case 'ERROR':
        console.log(chalk.red(`✗ ${message}`));
        break;
    }
  }

  info(msg, data) { this.log('INFO', msg, data); }
  success(msg, data) { this.log('SUCCESS', msg, data); }
  warn(msg, data) { this.log('WARN', msg, data); }
  error(msg, data) { this.log('ERROR', msg, data); }
}

// ============================================
// FILE DISCOVERY
// ============================================

function discoverFiles(directory, extensions) {
  const files = [];

  function traverse(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        traverse(fullPath);
      } else if (extensions.includes(path.extname(entry.name).toLowerCase())) {
        files.push(fullPath);
      }
    }
  }

  traverse(directory);
  return files;
}

// ============================================
// IMAGE OPTIMIZATION
// ============================================

async function optimizeImage(inputPath, outputDir, config) {
  return new Promise((resolve) => {
    try {
      const fileName = path.basename(inputPath, path.extname(inputPath));
      const fileSize = fs.statSync(inputPath).size;

      // Skip if file is too small
      if (fileSize < config.minImageSize) {
        resolve({
          status: 'skipped',
          reason: 'File too small',
          originalSize: fileSize,
          optimizedSize: fileSize
        });
        return;
      }

      // Ensure output directory exists
      if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
      }

      // Create WebP version
      const webpPath = path.join(outputDir, `${fileName}.webp`);
      sharp(inputPath)
        .webp({ quality: config.imageQuality })
        .toFile(webpPath, (err, info) => {
          if (err) {
            resolve({
              status: 'error',
              error: err.message,
              originalSize: fileSize,
              optimizedSize: 0
            });
            return;
          }

          const optimizedSize = fs.statSync(webpPath).size;

          resolve({
            status: 'success',
            format: 'webp',
            webpPath,
            originalSize: fileSize,
            optimizedSize
          });
        });
    } catch (error) {
      resolve({
        status: 'error',
        error: error.message,
        originalSize: fs.statSync(inputPath).size,
        optimizedSize: 0
      });
    }
  });
}

// ============================================
// VIDEO OPTIMIZATION - GPU ACCELERATED
// ============================================

async function optimizeVideo(inputPath, outputDir, config, isMobile = false) {
  return new Promise((resolve) => {
    try {
      const fileName = path.basename(inputPath, path.extname(inputPath));
      const fileSize = fs.statSync(inputPath).size;

      // Skip if file is too small
      if (fileSize < config.minVideoSize) {
        resolve({
          status: 'skipped',
          reason: 'File too small',
          originalSize: fileSize,
          optimizedSize: fileSize
        });
        return;
      }

      // Ensure output directory exists
      if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
      }

      // Get video dimensions
      ffmpeg.ffprobe(inputPath, (err, metadata) => {
        if (err) {
          resolve({
            status: 'error',
            error: err.message,
            originalSize: fileSize,
            optimizedSize: 0
          });
          return;
        }

        const videoStream = metadata.streams.find(s => s.codec_type === 'video');
        if (!videoStream) {
          resolve({
            status: 'error',
            error: 'No video stream found',
            originalSize: fileSize,
            optimizedSize: 0
          });
          return;
        }

        let width = videoStream.width;
        let height = videoStream.height;

        // Scale down if too large
        if (!isMobile && width > 1920) {
          const scale = 1920 / width;
          width = 1920;
          height = Math.round(height * scale);
        }

        // Scale for mobile
        if (isMobile) {
          const scale = 640 / width;
          width = 640;
          height = Math.round(height * scale);
        }

        // Use GPU encoder (HEVC_AMF for AMD)
        const mp4Output = path.join(outputDir, `${fileName}.mp4`);
        const results = {};
        let completedFormats = 0;
        const totalFormats = 2;

        // Convert to MP4 with GPU acceleration
        ffmpeg(inputPath)
          .outputOptions([
            '-c:v hevc_amf',  // AMD HEVC encoder - much faster!
            '-rc cqp',        // Quality mode
            `-qp_i ${Math.max(20, Math.min(51, 51 - config.videoQuality))}`, // Intra QP
            `-qp_p ${Math.max(20, Math.min(51, 51 - config.videoQuality))}`, // P-frame QP
            `-vf scale=w=${width}:h=trunc(ow/a/2)*2`,
            '-c:a aac',
            '-b:a 128k'
          ])
          .output(mp4Output)
          .on('end', () => {
            results.mp4 = {
              path: mp4Output,
              size: fs.statSync(mp4Output).size
            };
            completedFormats++;
            if (completedFormats === totalFormats) {
              finalize();
            }
          })
          .on('error', (err) => {
            results.mp4 = { error: err.message };
            completedFormats++;
            if (completedFormats === totalFormats) {
              finalize();
            }
          })
          .run();

        // Convert to WebM (VP9 - still uses CPU but optimized)
        ffmpeg(inputPath)
          .outputOptions([
            '-c:v libvpx-vp9',
            '-b:v 0',
            `-crf ${config.videoQuality}`,
            '-preset medium',
            `-vf scale=w=${width}:h=trunc(ow/a/2)*2`,
            '-c:a libopus',
            '-b:a 128k'
          ])
          .output(path.join(outputDir, `${fileName}.webm`))
          .on('end', () => {
            results.webm = {
              path: path.join(outputDir, `${fileName}.webm`),
              size: fs.statSync(path.join(outputDir, `${fileName}.webm`)).size
            };
            completedFormats++;
            if (completedFormats === totalFormats) {
              finalize();
            }
          })
          .on('error', (err) => {
            results.webm = { error: err.message };
            completedFormats++;
            if (completedFormats === totalFormats) {
              finalize();
            }
          })
          .run();

        function finalize() {
          const hasErrors = results.mp4?.error || results.webm?.error;
          const optimizedSize = (results.mp4?.size || 0) + (results.webm?.size || 0);

          if (hasErrors) {
            resolve({
              status: 'partial',
              originalSize: fileSize,
              optimizedSize: optimizedSize,
              results: results,
              errors: [results.mp4?.error, results.webm?.error].filter(Boolean)
            });
          } else {
            resolve({
              status: 'success',
              originalSize: fileSize,
              optimizedSize: optimizedSize,
              format: 'mp4+webm',
              results: results
            });
          }
        }
      });
    } catch (error) {
      resolve({
        status: 'error',
        error: error.message,
        originalSize: fs.statSync(inputPath).size
      });
    }
  });
}

// ============================================
// PROCESS WORKER QUEUE
// ============================================

class ProcessQueue {
  constructor(concurrency) {
    this.concurrency = concurrency;
    this.queue = [];
    this.running = 0;
    this.results = [];
  }

  add(task) {
    this.queue.push(task);
  }

  async process() {
    const promises = [];

    for (let i = 0; i < this.concurrency; i++) {
      promises.push(this.worker());
    }

    await Promise.all(promises);
    return this.results;
  }

  async worker() {
    while (this.queue.length > 0) {
      const task = this.queue.shift();
      try {
        const result = await task();
        this.results.push(result);
      } catch (error) {
        this.results.push({ status: 'error', error: error.message });
      }
    }
  }
}

// ============================================
// STATE MANAGEMENT
// ============================================

class ConversionState {
  constructor(stateFile) {
    this.stateFile = stateFile;
    this.state = this.load();
  }

  load() {
    try {
      if (fs.existsSync(this.stateFile)) {
        return JSON.parse(fs.readFileSync(this.stateFile, 'utf8'));
      }
    } catch (error) {
      console.warn('Could not load state file:', error.message);
    }
    return { completed: [], failed: [] };
  }

  save() {
    fs.writeFileSync(this.stateFile, JSON.stringify(this.state, null, 2));
  }

  isCompleted(filePath) {
    return this.state.completed.includes(filePath);
  }

  markCompleted(filePath) {
    if (!this.state.completed.includes(filePath)) {
      this.state.completed.push(filePath);
      this.save();
    }
  }

  markFailed(filePath, error) {
    if (!this.state.failed.includes(filePath)) {
      this.state.failed.push({ file: filePath, error });
      this.save();
    }
  }

  reset() {
    this.state = { completed: [], failed: [] };
    this.save();
  }
}

// ============================================
// REPORT GENERATION
// ============================================

function generateReport(results, reportFile) {
  const timestamp = new Date().toISOString();
  const imageResults = results.filter(r => r.type === 'image');
  const videoResults = results.filter(r => r.type === 'video');

  const totalOriginalSize = results.reduce((sum, r) => sum + (r.originalSize || 0), 0);
  const totalOptimizedSize = results.reduce((sum, r) => sum + (r.optimizedSize || 0), 0);
  const savingsPercent = totalOriginalSize > 0
    ? ((totalOriginalSize - totalOptimizedSize) / totalOriginalSize * 100).toFixed(1)
    : 0;

  const report = {
    timestamp,
    mode: 'GPU_ACCELERATED (AMD HEVC)',
    summary: {
      total_files_processed: results.filter(r => r.status !== 'skipped').length,
      total_files_skipped: results.filter(r => r.status === 'skipped').length,
      images_converted: imageResults.filter(r => r.status === 'success').length,
      videos_converted: videoResults.filter(r => r.status === 'success').length,
      failed_count: results.filter(r => r.status === 'error' || r.status === 'partial').length,
      original_size_mb: (totalOriginalSize / 1024 / 1024).toFixed(2),
      optimized_size_mb: (totalOptimizedSize / 1024 / 1024).toFixed(2),
      savings_percent: savingsPercent
    },
    files: results.map(r => ({
      original_path: r.originalPath,
      optimized_path: r.optimizedPath,
      original_size_kb: (r.originalSize / 1024).toFixed(2),
      optimized_size_kb: (r.optimizedSize / 1024).toFixed(2),
      format: r.format,
      type: r.type,
      status: r.status,
      error: r.error || null,
      reason: r.reason || null
    })),
    errors: results.filter(r => r.status === 'error').map(r => ({
      file: r.originalPath,
      error: r.error
    }))
  };

  fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));
  return report;
}

// ============================================
// MAIN CONVERSION LOGIC
// ============================================

async function main() {
  // Parse CLI arguments
  const argv = await yargs(hideBin(process.argv))
    .option('source', {
      alias: 's',
      describe: 'Source directory containing media',
      type: 'string',
      default: DEFAULT_CONFIG.source
    })
    .option('output', {
      alias: 'o',
      describe: 'Output directory for optimized media',
      type: 'string',
      default: DEFAULT_CONFIG.output
    })
    .option('image-quality', {
      describe: 'JPEG/WebP quality (0-100)',
      type: 'number',
      default: DEFAULT_CONFIG.imageQuality
    })
    .option('video-quality', {
      describe: 'Video CRF quality, lower=better (0-51)',
      type: 'number',
      default: DEFAULT_CONFIG.videoQuality
    })
    .option('parallel', {
      alias: 'p',
      describe: 'Number of parallel workers',
      type: 'number',
      default: DEFAULT_CONFIG.parallel
    })
    .option('dry-run', {
      describe: 'Preview conversions without actually converting',
      type: 'boolean',
      default: false
    })
    .option('continue', {
      describe: 'Resume from last successful file',
      type: 'boolean',
      default: false
    })
    .option('skip-images', {
      describe: 'Skip image conversion',
      type: 'boolean',
      default: false
    })
    .option('skip-videos', {
      describe: 'Skip video conversion',
      type: 'boolean',
      default: false
    })
    .option('verbose', {
      alias: 'v',
      describe: 'Detailed logging',
      type: 'boolean',
      default: false
    })
    .help()
    .alias('help', 'h')
    .parse();

  // Setup directories and logging
  const config = {
    ...DEFAULT_CONFIG,
    imageQuality: argv['image-quality'],
    videoQuality: argv['video-quality'],
    parallel: argv.parallel
  };

  const outputDir = path.resolve(argv.output);
  const sourceDir = path.resolve(argv.source);
  const logFile = path.join(outputDir, 'conversion.log');
  const reportFile = path.join(outputDir, 'conversion-report.json');
  const stateFile = path.join(outputDir, '.conversion-state.json');

  // Create output directory
  if (!argv['dry-run']) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const logger = new Logger(logFile);
  const state = new ConversionState(stateFile);

  // Start
  console.log('\n' + chalk.cyan.bold('╔════════════════════════════════════════╗'));
  console.log(chalk.cyan.bold('║   MEDIA OPTIMIZATION BATCH CONVERTER    ║'));
  console.log(chalk.cyan.bold('║   🚀 GPU ACCELERATED (AMD HEVC)        ║'));
  console.log(chalk.cyan.bold('╚════════════════════════════════════════╝\n'));

  logger.info('Starting GPU-accelerated media optimization', {
    sourceDir,
    outputDir,
    dryRun: argv['dry-run'],
    continue: argv.continue,
    config
  });

  // Discover files
  let imageFiles = [];
  let videoFiles = [];

  if (!argv['skip-images']) {
    console.log(chalk.blue('📸 Discovering images...'));
    imageFiles = discoverFiles(sourceDir, config.imageFormats.source);
    logger.info(`Found ${imageFiles.length} images`);
  }

  if (!argv['skip-videos']) {
    console.log(chalk.blue('🎥 Discovering videos...'));
    videoFiles = discoverFiles(sourceDir, config.videoFormats.source);
    logger.info(`Found ${videoFiles.length} videos`);
  }

  const allFiles = [...imageFiles, ...videoFiles];
  const filteredFiles = argv.continue
    ? allFiles.filter(f => !state.isCompleted(f))
    : allFiles;

  console.log(`\n${chalk.yellow(`Processing ${filteredFiles.length} files in batches of ${config.parallel}...\n`)}`);

  // Setup progress bar
  const progressBar = new cliProgress.SingleBar({
    format: '{bar} {percentage}% | {value}/{total} files | {duration_formatted}',
    barCompleteChar: '█',
    barIncompleteChar: '░',
    hideCursor: true,
    stopOnComplete: true
  });

  progressBar.start(filteredFiles.length, 0);

  // Create task queue
  const queue = new ProcessQueue(config.parallel);
  const allResults = [];

  for (const file of filteredFiles) {
    const isImage = imageFiles.includes(file);
    const isVideo = videoFiles.includes(file);
    const relativeFile = path.relative(sourceDir, file);

    queue.add(async () => {
      let result;

      try {
        if (argv['dry-run']) {
          result = {
            originalPath: relativeFile,
            optimizedPath: 'N/A (dry-run)',
            type: isImage ? 'image' : 'video',
            status: 'preview',
            originalSize: fs.statSync(file).size,
            optimizedSize: 0
          };
        } else if (isImage) {
          const imageOutputDir = path.join(outputDir, config.imageDirs.original);
          const optimizeResult = await optimizeImage(file, imageOutputDir, config);

          result = {
            originalPath: relativeFile,
            optimizedPath: optimizeResult.webpPath
              ? path.relative(sourceDir, optimizeResult.webpPath)
              : null,
            type: 'image',
            ...optimizeResult
          };

          if (optimizeResult.status === 'success') {
            state.markCompleted(file);
          }
        } else if (isVideo) {
          const videoOutputDir = path.join(outputDir, config.videoDirs.original);
          const optimizeResult = await optimizeVideo(file, videoOutputDir, config, false);

          result = {
            originalPath: relativeFile,
            optimizedPath: optimizeResult.results?.mp4?.path ?
              path.relative(sourceDir, optimizeResult.results.mp4.path)
              : null,
            type: 'video',
            ...optimizeResult
          };

          // Always create mobile variant for videos
          if (optimizeResult.status === 'success' || optimizeResult.status === 'partial') {
            const mobileOutputDir = path.join(outputDir, config.videoDirs.mobile);
            const mobileResult = await optimizeVideo(file, mobileOutputDir, config, true);
            result.mobileVariant = mobileResult;
          }

          if (result.status === 'success') {
            state.markCompleted(file);
          }
        }

        allResults.push(result);
        progressBar.increment();
      } catch (error) {
        const result = {
          originalPath: relativeFile,
          type: isImage ? 'image' : 'video',
          status: 'error',
          error: error.message,
          originalSize: fs.statSync(file).size,
          optimizedSize: 0
        };
        allResults.push(result);
        state.markFailed(file, error.message);
        logger.error(`Failed to process ${relativeFile}`, { error: error.message });
        progressBar.increment();
      }
    });
  }

  // Execute queue
  if (filteredFiles.length > 0) {
    await queue.process();
  }

  progressBar.stop();

  // Generate report
  if (!argv['dry-run']) {
    const report = generateReport(allResults, reportFile);

    // Display summary
    console.log('\n' + chalk.cyan.bold('╔════════════════════════════════════════╗'));
    console.log(chalk.cyan.bold('║         CONVERSION COMPLETE             ║'));
    console.log(chalk.cyan.bold('╚════════════════════════════════════════╝\n'));

    console.log(chalk.bold('Summary:'));
    console.log(`  ${chalk.green('✓')} Total processed:    ${report.summary.total_files_processed}`);
    console.log(`  ${chalk.yellow('⊝')} Skipped:           ${report.summary.total_files_skipped}`);
    console.log(`  ${chalk.green('✓')} Images converted:  ${report.summary.images_converted}`);
    console.log(`  ${chalk.green('✓')} Videos converted:  ${report.summary.videos_converted}`);
    console.log(`  ${chalk.red('✗')} Failed:            ${report.summary.failed_count}`);
    console.log(`\n${chalk.bold('Size Reduction:')}`);
    console.log(`  Original:  ${chalk.yellow(report.summary.original_size_mb)} MB`);
    console.log(`  Optimized: ${chalk.green(report.summary.optimized_size_mb)} MB`);
    console.log(`  Saved:     ${chalk.green(report.summary.savings_percent + '%')}\n`);

    logger.success('Conversion complete', report.summary);
    console.log(chalk.dim(`📋 Full report: ${reportFile}`));
    console.log(chalk.dim(`📝 Logs: ${logFile}\n`));

    if (report.summary.failed_count > 0) {
      console.log(chalk.red.bold('⚠ Errors encountered:'));
      report.errors.slice(0, 5).forEach(err => {
        console.log(chalk.red(`  • ${err.file}: ${err.error}`));
      });
      if (report.errors.length > 5) {
        console.log(chalk.red(`  ... and ${report.errors.length - 5} more`));
      }
      console.log('');
    }
  } else {
    // Dry-run summary
    console.log('\n' + chalk.cyan.bold('╔════════════════════════════════════════╗'));
    console.log(chalk.cyan.bold('║          DRY-RUN PREVIEW               ║'));
    console.log(chalk.cyan.bold('╚════════════════════════════════════════╝\n'));

    const imageCount = allResults.filter(r => r.type === 'image').length;
    const videoCount = allResults.filter(r => r.type === 'video').length;
    const totalSize = allResults.reduce((sum, r) => sum + (r.originalSize || 0), 0);

    console.log(chalk.bold('Would process:'));
    console.log(`  Images:   ${imageCount}`);
    console.log(`  Videos:   ${videoCount}`);
    console.log(`  Total:    ${imageCount + videoCount}`);
    console.log(`  Size:     ${(totalSize / 1024 / 1024).toFixed(2)} MB\n`);
    console.log(chalk.yellow('Run without --dry-run to start conversion.\n'));
  }
}

// Run
main().catch(error => {
  console.error(chalk.red('Fatal error:'), error);
  process.exit(1);
});
