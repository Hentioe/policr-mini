use magick_rust::{
    bindings::{
        DestroyPixelIterator, NewPixelIterator, PixelGetCurrentIteratorRow, PixelSetColor,
        PixelSetIteratorRow, PixelSyncIterator,
    },
    magick_wand_genesis, MagickWand,
};
use rand::prelude::*;
use std::{ffi::c_char, path::PathBuf, str::Utf8Error, sync::Once};
use thiserror::Error as ThisError;
use uuid::Uuid;

static START: Once = Once::new();

mod atoms {
    rustler::atoms! {
        invalid_unicode,
        cannot_get_file_name,
        magick_exec_error,
        illegal_utf8
    }
}

#[derive(ThisError, Debug)]
pub enum Error {
    // 无效的 Unicode
    #[error("Invalid unicode")]
    InvalidUnicode,
    // 无法获取文件名
    #[error("Cannot get file name")]
    CannotGetFileName,
    // 转换 MagickError
    #[error("Magick: {0}")]
    MagickError(#[from] magick_rust::MagickError),
    // 转换 Utf8Error
    #[error("Utf8: {0}")]
    Utf8Error(#[from] Utf8Error),
}

impl rustler::types::Encoder for Error {
    fn encode<'a>(&self, env: rustler::Env<'a>) -> rustler::Term<'a> {
        // TODO: 此处应该进一步包装错误的具体信息，返回有细节的错误结构。
        let error = match self {
            Error::InvalidUnicode => atoms::invalid_unicode(),
            Error::CannotGetFileName => atoms::cannot_get_file_name(),
            Error::MagickError(_) => atoms::magick_exec_error(),
            Error::Utf8Error(_) => atoms::illegal_utf8(),
        };

        error.encode(env)
    }
}

type Result<T> = std::result::Result<T, Error>;

rustler::init!("Elixir.PolicrMini.ImgKit", [rewrite_image]);

#[rustler::nif]
fn rewrite_image(image: String, outout_dir: String) -> Result<String> {
    _rewrite_image(image.into(), outout_dir.into())
}

fn _rewrite_image(image: PathBuf, output_dir: PathBuf) -> Result<String> {
    START.call_once(magick_wand_genesis);

    // 创建 wand 并读取图片。
    let wand = MagickWand::new();
    wand.read_image(image.to_str().ok_or(Error::InvalidUnicode)?)?;
    let format = wand.get_image_format()?.to_lowercase();

    let width = wand.get_image_width();
    let height = wand.get_image_height();

    // 生成随机行和列。
    let mut rng = thread_rng();
    let rand_row = rng.gen_range(1..=height);
    let rand_col = rng.gen_range(1..=width);

    unsafe {
        // 创建像素迭代器。
        let iterator_ptr = NewPixelIterator(wand.wand);
        let row_width_ptr = &mut (1_usize) as *mut usize;
        // 设置当前的像素行。
        PixelSetIteratorRow(iterator_ptr, (rand_row - 1) as isize);
        // 获取当前行的像素列表。
        let pixels = std::slice::from_raw_parts_mut(
            PixelGetCurrentIteratorRow(iterator_ptr, row_width_ptr),
            rand_col,
        );
        // 设置列中的随机像素为黑色。
        PixelSetColor(pixels[rand_col - 1], "#000000\0".as_ptr() as *const c_char);
        // 同步像素迭代器。
        PixelSyncIterator(iterator_ptr);
        // 销毁像素迭代器。
        DestroyPixelIterator(iterator_ptr);
    };
    // 写入图片到输出位置（使用输入的图像格式作为扩展名）。
    let file_name = format!("rewritten-{}", random_fname(&format));
    let path_buf = output_dir.join(file_name);
    let file_path = path_buf.to_str().ok_or(Error::InvalidUnicode)?;
    wand.write_image(file_path)?;

    // 返回输出图片的路径。
    Ok(file_path.to_owned())
}

fn random_fname(ext: &str) -> String {
    format!("{}.{}", Uuid::new_v4(), ext)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rewrite_image() {
        let assets_path = PathBuf::from("..").join("..").join("test").join("assets");

        let image = assets_path.join("white-10x10.jpg");
        let output_dir = assets_path.join("output");
        let r = _rewrite_image(image, output_dir);

        assert!(matches!(r, Ok(_)));
        assert!(PathBuf::from(r.unwrap()).exists());
    }
}
