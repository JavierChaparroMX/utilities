#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Generate HTML report with before/after comparisons
 * Usage: node generate-report-html.js [report-json-path]
 */

function generateHTMLReport(reportJsonPath = './public-optimized/conversion-report.json') {
  if (!fs.existsSync(reportJsonPath)) {
    console.error(`Report file not found: ${reportJsonPath}`);
    process.exit(1);
  }

  const report = JSON.parse(fs.readFileSync(reportJsonPath, 'utf8'));
  const reportDir = path.dirname(reportJsonPath);
  const htmlPath = path.join(reportDir, 'conversion-report.html');

  // Separate images and videos
  const images = report.files.filter(f => f.type === 'image' && f.status === 'success'),
  videos = report.files.filter(f => f.type === 'video' && f.status === 'success');

  const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Media Optimization Report</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 2rem;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            overflow: hidden;
        }

        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 3rem 2rem;
            text-align: center;
        }

        header h1 {
            font-size: 2.5rem;
            margin-bottom: 0.5rem;
        }

        header p {
            font-size: 1rem;
            opacity: 0.9;
        }

        .timestamp {
            font-size: 0.9rem;
            opacity: 0.8;
            margin-top: 0.5rem;
        }

        .summary {
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            padding: 2rem;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
        }

        .stat-card {
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }

        .stat-card h3 {
            font-size: 0.9rem;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 0.5rem;
        }

        .stat-card .value {
            font-size: 2rem;
            font-weight: bold;
            color: #667eea;
        }

        .stat-card .unit {
            font-size: 0.9rem;
            color: #999;
            margin-left: 0.5rem;
        }

        .stat-card.savings {
            background: linear-gradient(135deg, #84fab0 0%, #8fd3f4 100%);
        }

        .stat-card.savings .value {
            color: #27ae60;
        }

        .content {
            padding: 2rem;
        }

        section {
            margin-bottom: 3rem;
        }

        section h2 {
            font-size: 1.8rem;
            color: #333;
            margin-bottom: 1.5rem;
            padding-bottom: 0.5rem;
            border-bottom: 3px solid #667eea;
        }

        .gallery {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 2rem;
        }

        .item-card {
            background: #f9f9f9;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s, box-shadow 0.3s;
        }

        .item-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.15);
        }

        .item-preview {
            background: #f0f0f0;
            height: 200px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 3rem;
            color: #ddd;
            position: relative;
            overflow: hidden;
        }

        .item-preview img,
        .item-preview video {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .item-details {
            padding: 1.5rem;
        }

        .item-title {
            font-weight: 600;
            color: #333;
            margin-bottom: 0.5rem;
            word-break: break-word;
        }

        .item-format {
            font-size: 0.85rem;
            color: #999;
            margin-bottom: 1rem;
        }

        .size-comparison {
            display: flex;
            gap: 1rem;
            margin-bottom: 1rem;
            font-size: 0.9rem;
        }

        .size-info {
            flex: 1;
        }

        .size-label {
            color: #666;
            font-size: 0.8rem;
            text-transform: uppercase;
            margin-bottom: 0.3rem;
        }

        .size-value {
            font-weight: 600;
            color: #333;
        }

        .savings-amount {
            background: #e8f5e9;
            padding: 0.75rem;
            border-radius: 4px;
            text-align: center;
            color: #27ae60;
            font-weight: 600;
        }

        .status-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
            margin-top: 0.5rem;
        }

        .status-success {
            background: #e8f5e9;
            color: #27ae60;
        }

        .status-error {
            background: #ffebee;
            color: #c62828;
        }

        .status-skipped {
            background: #f5f5f5;
            color: #666;
        }

        .errors-section {
            background: #ffebee;
            padding: 2rem;
            border-radius: 8px;
            border-left: 4px solid #c62828;
        }

        .error-item {
            background: white;
            padding: 1rem;
            margin-bottom: 1rem;
            border-radius: 4px;
            border-left: 3px solid #c62828;
        }

        .error-file {
            font-weight: 600;
            color: #333;
            margin-bottom: 0.25rem;
        }

        .error-message {
            color: #c62828;
            font-size: 0.9rem;
        }

        footer {
            background: #f5f5f5;
            padding: 2rem;
            text-align: center;
            color: #666;
            font-size: 0.9rem;
        }

        .progress-bar {
            background: #e0e0e0;
            height: 8px;
            border-radius: 4px;
            overflow: hidden;
            margin: 0.75rem 0;
        }

        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            border-radius: 4px;
        }

        @media (max-width: 768px) {
            header h1 {
                font-size: 1.8rem;
            }

            .summary {
                grid-template-columns: 1fr;
            }

            .gallery {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>📊 Media Optimization Report</h1>
            <p>Automated batch conversion and compression results</p>
            <div class="timestamp">${new Date(report.timestamp).toLocaleString()}</div>
        </header>

        <div class="summary">
            <div class="stat-card">
                <h3>Total Files Processed</h3>
                <div class="value">${report.summary.total_files_processed}</div>
            </div>
            <div class="stat-card">
                <h3>Files Skipped</h3>
                <div class="value">${report.summary.total_files_skipped}</div>
            </div>
            <div class="stat-card">
                <h3>Images Converted</h3>
                <div class="value">${report.summary.images_converted}</div>
            </div>
            <div class="stat-card">
                <h3>Videos Converted</h3>
                <div class="value">${report.summary.videos_converted}</div>
            </div>
            <div class="stat-card">
                <h3>Original Size</h3>
                <div class="value">${report.summary.original_size_mb}<span class="unit">MB</span></div>
            </div>
            <div class="stat-card">
                <h3>Optimized Size</h3>
                <div class="value">${report.summary.optimized_size_mb}<span class="unit">MB</span></div>
            </div>
            <div class="stat-card savings">
                <h3>Total Savings</h3>
                <div class="value">${report.summary.savings_percent}%</div>
            </div>
        </div>

        <div class="content">
            ${images.length > 0 ? `
            <section>
                <h2>🖼️ Images (${images.length})</h2>
                <div class="gallery">
                    ${images.map(file => {
                        const savings = ((file.original_size_kb - file.optimized_size_kb) / file.original_size_kb * 100).toFixed(1);
                        return `
                        <div class="item-card">
                            <div class="item-preview">🖼️</div>
                            <div class="item-details">
                                <div class="item-title" title="${file.original_path}">${path.basename(file.original_path)}</div>
                                <div class="item-format">${file.format}</div>
                                <div class="size-comparison">
                                    <div class="size-info">
                                        <div class="size-label">Original</div>
                                        <div class="size-value">${file.original_size_kb} KB</div>
                                    </div>
                                    <div class="size-info">
                                        <div class="size-label">Optimized</div>
                                        <div class="size-value">${file.optimized_size_kb} KB</div>
                                    </div>
                                </div>
                                <div class="savings-amount">↓ ${savings}%</div>
                                <span class="status-badge status-success">✓ Success</span>
                            </div>
                        </div>
                        `;
                    }).join('')}
                </div>
            </section>
            ` : ''}

            ${videos.length > 0 ? `
            <section>
                <h2>🎬 Videos (${videos.length})</h2>
                <div class="gallery">
                    ${videos.map(file => {
                        const savings = ((file.original_size_kb - file.optimized_size_kb) / file.original_size_kb * 100).toFixed(1);
                        return `
                        <div class="item-card">
                            <div class="item-preview">🎥</div>
                            <div class="item-details">
                                <div class="item-title" title="${file.original_path}">${path.basename(file.original_path)}</div>
                                <div class="item-format">${file.format}</div>
                                <div class="size-comparison">
                                    <div class="size-info">
                                        <div class="size-label">Original</div>
                                        <div class="size-value">${file.original_size_kb} KB</div>
                                    </div>
                                    <div class="size-info">
                                        <div class="size-label">Optimized</div>
                                        <div class="size-value">${file.optimized_size_kb} KB</div>
                                    </div>
                                </div>
                                <div class="savings-amount">↓ ${savings}%</div>
                                <span class="status-badge status-success">✓ Success</span>
                            </div>
                        </div>
                        `;
                    }).join('')}
                </div>
            </section>
            ` : ''}

            ${report.errors.length > 0 ? `
            <section class="errors-section">
                <h2>⚠️ Errors (${report.errors.length})</h2>
                ${report.errors.map(error => `
                <div class="error-item">
                    <div class="error-file">${error.file}</div>
                    <div class="error-message">${error.error}</div>
                </div>
                `).join('')}
            </section>
            ` : ''}
        </div>

        <footer>
            <p>Generated on ${new Date(report.timestamp).toLocaleString()}</p>
            <p>Media Optimization Script v1.0</p>
        </footer>
    </div>
</body>
</html>`;

  fs.writeFileSync(htmlPath, htmlContent, 'utf8');
  console.log(`✅ HTML report generated: ${htmlPath}`);
}

// Main
const reportPath = process.argv[2] || './public-optimized/conversion-report.json';
generateHTMLReport(reportPath);
