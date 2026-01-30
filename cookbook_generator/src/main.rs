use anyhow::{anyhow, Result};
use clap::Parser;
use regex::Regex;
use std::collections::HashMap;
use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::Command;
use walkdir::WalkDir;

#[derive(Parser)]
#[command(name = "cookbook_generator")]
#[command(bin_name = "cookbook_generator")]
enum Cli {
    #[command(about = "Builds the cookbook from markdown chapters")]
    Build(BuildArgs),
    #[command(about = "Creates a default config.txt file if it doesn't exist")]
    Init(InitArgs),
}

#[derive(clap::Args)]
struct InitArgs {}

#[derive(clap::Args)]
struct BuildArgs {
    #[arg(short, long, help = "Skips interactive prompts and uses default values")]
    skip_prompts: bool,
    #[arg(short, long, default_value = "config.txt", help = "Path to the configuration file")]
    config: String,
}

struct Config {
    params: HashMap<String, String>,
}

impl Config {
    fn load(path: &str) -> Result<Self> {
        let content = fs::read_to_string(path)?;
        let mut params = HashMap::new();
        for line in content.lines() {
            let parts: Vec<&str> = line.splitn(2, '=').collect();
            if parts.len() == 2 {
                params.insert(parts[0].trim().to_string(), parts[1].trim().to_string());
            }
        }
        Ok(Config { params })
    }

    fn get(&self, key: &str) -> Result<&String> {
        self.params
            .get(key)
            .ok_or_else(|| anyhow!("Missing config key: {}", key))
    }
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli {
        Cli::Build(args) => {
            build(args)?;
        }
        Cli::Init(_args) => {
            init()?;
        }
    }
    Ok(())
}

fn init() -> Result<()> {
    let config_path = Path::new("config.txt");
    if config_path.exists() {
        println!("Config file already exists: config.txt");
    } else {
        let default_config_content = r#"pdf_sans_family = Bai Jamjuree
pdf_mono_family = DejaVu Sans Mono
pdf_standard_font = sans
pdf_default_font_size = 20
pdf_mono_font_size = 20
pdf_page_margin_left = 48
pdf_page_margin_right = 48
pdf_page_margin_top = 72
pdf_page_margin_bottom = 108
paper_size = a4
pdf_toc_title=สารบัญ
"#;
        fs::write(config_path, default_config_content)?;
        println!("Created default config file: config.txt");
    }
    Ok(())
}

fn build(args: BuildArgs) -> Result<()> {
    let config = Config::load(&args.config)?;

    let build_dir = Path::new("build");
    if build_dir.exists() {
        fs::remove_dir_all(build_dir)?;
    }
    fs::create_dir(build_dir)?;

    let chapters_dir = Path::new("chapters");

    // Combine chapters
    combine_chapters(chapters_dir, build_dir, "epub_input.md", |f| {
        f.extension().map_or(false, |ext| ext == "md")
    })?;
    combine_chapters(chapters_dir, build_dir, "sample_epub_input.md", |f| {
        f.file_name()
            .and_then(|n| n.to_str())
            .map_or(false, |s| s.starts_with("00") || s.starts_with("01"))
            && f.extension().map_or(false, |ext| ext == "md")
    })?;
    combine_chapters(chapters_dir, build_dir, "pdf_input.md", |f| {
        f.file_name()
            .and_then(|n| n.to_str())
            .map_or(false, |s| s != "00_preface.md")
            && f.extension().map_or(false, |ext| ext == "md")
    })?;

    // Run external commands
    run_command(
        "pandoc",
        &[
            "-o",
            "build/ebook.epub",
            "--top-level-division=chapter",
            "--epub-cover-image=images/cover.png",
            "--css=epub.css",
            "-i",
            "epub.yaml",
            "build/epub_input.md",
        ],
    )?;
    run_command(
        "ebook-convert",
        &[
            "build/ebook.epub",
            "build/ebook_epub3.epub",
            "--epub-version",
            "3",
            "--embed-all-fonts",
        ],
    )?;
    run_command(
        "pandoc",
        &[
            "-o",
            "build/sample_ebook.epub",
            "--top-level-division=chapter",
            "--epub-cover-image=images/cover.png",
            "--css=epub.css",
            "-i",
            "epub.yaml",
            "build/sample_epub_input.md",
        ],
    )?;
    run_command(
        "ebook-convert",
        &[
            "build/sample_ebook.epub",
            "build/sample_ebook_epub3.epub",
            "--epub-version",
            "3",
            "--embed-all-fonts",
        ],
    )?;
    run_command(
        "pandoc",
        &[
            "-o",
            "build/preface.epub",
            "--top-level-division=chapter",
            "--css=epub.css",
            "-i",
            "epub.yaml",
            "chapters/00_preface.md",
        ],
    )?;
    run_command(
        "pandoc",
        &[
            "-o",
            "build/output.epub",
            "--top-level-division=chapter",
            "--css=epub.css",
            "build/pdf_input.md",
        ],
    )?;

    let pdf_sans_family = config.get("pdf_sans_family")?;
    let pdf_mono_family = config.get("pdf_mono_family")?;
    let pdf_standard_font = config.get("pdf_standard_font")?;
    let pdf_default_font_size = config.get("pdf_default_font_size")?;
    let pdf_mono_font_size = config.get("pdf_mono_font_size")?;
    let pdf_page_margin_left = config.get("pdf_page_margin_left")?;
    let pdf_page_margin_right = config.get("pdf_page_margin_right")?;
    let pdf_page_margin_top = config.get("pdf_page_margin_top")?;
    let pdf_page_margin_bottom = config.get("pdf_page_margin_bottom")?;
    let paper_size = config.get("paper_size")?;
    let pdf_toc_title = config.get("pdf_toc_title")?;

    run_command(
        "ebook-convert",
        &[
            "build/preface.epub",
            "build/preface.pdf",
            "--extra-css",
            "calibre_extra_css.css",
            "--filter-css",
            "--insert-blank-line",
            "--paper-size",
            paper_size,
            "--embed-all-fonts",
            "--pdf-sans-family",
            pdf_sans_family,
            "--pdf-mono-family",
            pdf_mono_family,
            "--pdf-standard-font",
            pdf_standard_font,
            "--pdf-default-font-size",
            pdf_default_font_size,
            "--pdf-mono-font-size",
            pdf_mono_font_size,
            "--pdf-page-margin-left",
            pdf_page_margin_left,
            "--pdf-page-margin-right",
            pdf_page_margin_right,
            "--pdf-page-margin-top",
            pdf_page_margin_top,
            "--pdf-page-margin-bottom",
            pdf_page_margin_bottom,
        ],
    )?;

    run_command(
        "ebook-convert",
        &[
            "build/output.epub",
            "build/output.pdf",
            "--extra-css",
            "calibre_extra_css.css",
            "--filter-css",
            "--insert-blank-line",
            "--pdf-add-toc",
            "--toc-title",
            pdf_toc_title,
            "--paper-size",
            paper_size,
            "--embed-all-fonts",
            "--pdf-sans-family",
            pdf_sans_family,
            "--pdf-mono-family",
            pdf_mono_family,
            "--pdf-standard-font",
            pdf_standard_font,
            "--pdf-default-font-size",
            pdf_default_font_size,
            "--pdf-mono-font-size",
            pdf_mono_font_size,
            "--pdf-page-margin-left",
            pdf_page_margin_left,
            "--pdf-page-margin-right",
            pdf_page_margin_right,
            "--pdf-page-margin-top",
            pdf_page_margin_top,
            "--pdf-page-margin-bottom",
            pdf_page_margin_bottom,
        ],
    )?;

    let pdf_path = "build/output.pdf";
    let pdf_info_output = Command::new("pdfcpu").arg("info").arg(pdf_path).output()?;
    let pdf_info = String::from_utf8_lossy(&pdf_info_output.stdout);
    let re = Regex::new(r"Page count:\s*(\d+)")?;
    let page_count: i32 = re
        .captures(&pdf_info)
        .and_then(|caps| caps.get(1))
        .and_then(|m| m.as_str().parse().ok())
        .ok_or_else(|| anyhow!("Could not find page count"))?;

    println!("Total number of pages: {}", page_count);

    let split_page_number = if args.skip_prompts {
        1
    } else {
        read_input("Enter the page number to split at: ")?.parse()?
    };

    run_command(
        "pdfcpu",
        &[
            "split",
            "-m",
            "page",
            pdf_path,
            "build/",
            &split_page_number.to_string(),
        ],
    )?;

    let end_page = split_page_number;
    let pdf_file_path_to_stamp = format!("build/output_1-{}.pdf", end_page - 1);
    let stamped_output_path = format!("build/output_stamp_1-{}.pdf", end_page - 1);

    run_command(
        "pdfcpu",
        &[
            "stamp",
            "add",
            "-mode",
            "text",
            "--",
            "%p",
            "points:14,scale:1.0 abs,pos:br,rot:0,ma:60",
            &pdf_file_path_to_stamp,
            &stamped_output_path,
        ],
    )?;

    let merged_file_path = "build/ebook.pdf";
    let cover_file_path = "images/cover.pdf";
    let preface_file_path = "build/preface.pdf";
    let output_path_split = format!("build/output_{}-{}.pdf", split_page_number, page_count);
    let back_cover_path = "images/back_cover.pdf";

    run_command(
        "pdfcpu",
        &[
            "merge",
            merged_file_path,
            cover_file_path,
            preface_file_path,
            &output_path_split,
            &stamped_output_path,
            back_cover_path,
        ],
    )?;

    let page_to_remove = if args.skip_prompts {
        1
    } else {
        read_input("Enter the page number to remove: ")?.parse()?
    };

    run_command(
        "pdfcpu",
        &[
            "pages",
            "rem",
            "-pages",
            &page_to_remove.to_string(),
            merged_file_path,
        ],
    )?;

    println!("Optimize PDFs...");

    let sample_pages = (page_count as f32 * 0.1).ceil().max(1.0) as i32;
    let page_range = format!("1-{}", sample_pages);

    println!("Total pages   : {}", page_count);
    println!("Sample pages  : {} ({})", sample_pages, page_range);

    run_command(
        "pdfcpu",
        &[
            "trim",
            "-pages",
            &page_range,
            merged_file_path,
            "build/sample_ebook.pdf",
        ],
    )?;

    cleanup_build_files("build")?;

    println!("All done!");
    println!("Build completed successfully!");
    println!("You can find the output files in the build directory.");

    Ok(())
}

fn combine_chapters<F>(
    chapters_dir: &Path,
    build_dir: &Path,
    output_filename: &str,
    filter: F,
) -> Result<()>
where
    F: Fn(&Path) -> bool,
{
    let mut output_path = build_dir.to_path_buf();
    output_path.push(output_filename);
    let mut output_file = fs::File::create(&output_path)?;

    let mut paths: Vec<PathBuf> = fs::read_dir(chapters_dir)?
        .filter_map(|entry| entry.ok())
        .map(|entry| entry.path())
        .filter(|path| filter(path))
        .collect();
    paths.sort();

    for path in paths {
        println!("Processing {}", path.display());
        let content = fs::read_to_string(path)?;
        writeln!(output_file, "\n{}\n", content)?;
    }
    Ok(())
}

fn run_command(cmd: &str, args: &[&str]) -> Result<()> {
    println!("Running: {} {}", cmd, args.join(" "));
    let status = Command::new(cmd).args(args).status()?;
    if !status.success() {
        return Err(anyhow!("Command failed: {} {}", cmd, args.join(" ")));
    }
    Ok(())
}

fn read_input(prompt: &str) -> Result<String> {
    print!("{}", prompt);
    io::stdout().flush()?;
    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    Ok(input.trim().to_string())
}

fn cleanup_build_files(build_dir: &str) -> Result<()> {
    for entry in WalkDir::new(build_dir) {
        let entry = entry?;
        let path = entry.path();
        if path.is_file() {
            let file_name = path.file_name().and_then(|n| n.to_str()).unwrap_or("");
            if file_name != "ebook.pdf"
                && file_name != "sample_ebook.pdf"
                && file_name != "ebook_epub3.epub"
                && file_name != "sample_ebook_epub3.epub"
            {
                fs::remove_file(path)?;
            }
        }
    }
    Ok(())
}
