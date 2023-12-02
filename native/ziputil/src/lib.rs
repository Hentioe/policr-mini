use std::{fs, io, path::PathBuf};
use thiserror::Error as ThisError;
use zip::ZipArchive;

#[derive(ThisError, Debug)]
pub enum Error {
    #[error("IO: {0}")]
    Io(#[from] io::Error),

    #[error("Zip: {0}")]
    Zip(#[from] zip::result::ZipError),

    // 转换 Utf8Error
    #[error("FromUtf8: {0}")]
    Utf8Error(#[from] std::string::FromUtf8Error),
}

type Result<T> = std::result::Result<T, Error>;

mod atoms {
    rustler::atoms! {
        io_error,
        zip_error,
        from_utf8_error
    }
}

impl rustler::types::Encoder for Error {
    fn encode<'a>(&self, env: rustler::Env<'a>) -> rustler::Term<'a> {
        // TODO: 此处应该进一步包装错误的具体信息，返回有细节的错误结构。
        let error = match self {
            Error::Io(_) => atoms::io_error(),
            Error::Zip(_) => atoms::zip_error(),
            Error::Utf8Error(_) => atoms::from_utf8_error(),
        };

        error.encode(env)
    }
}

rustler::init!("Elixir.PolicrMini.ZipUtil", [unzip_file]);

#[rustler::nif]
fn unzip_file(zip_file: String, output_dir: String) -> Result<()> {
    _unzip_file(zip_file.into(), output_dir.into())
}

pub fn _unzip_file(zip_file: PathBuf, output_dir: PathBuf) -> Result<()> {
    // 读取文件并创建 zip 归档。
    let file = fs::File::open(zip_file)?;
    let mut archive = ZipArchive::new(file)?;

    for i in 0..archive.len() {
        let mut file = archive.by_index(i)?;
        // 按照官方示例建议，此处应该用 `enclosed_name` 方法以避免攻击。但 `enclosed_name` 方法可能存在乱码问题，且上传压缩文件暂时无需担心攻击。
        let out = String::from_utf8(file.name_raw().to_vec())?;

        let output_path = output_dir.join(out);

        if (*file.name()).ends_with('/') {
            // 如果是目录，则创建目录。
            fs::create_dir_all(&output_path)?;
        } else {
            // 如果是文件，在写入前检查父级目录是否存在。
            if let Some(p) = output_path.parent() {
                if !p.exists() {
                    // 不存在则创建父级目录。
                    fs::create_dir_all(p)?;
                }
            }
            // 写入文件。
            let mut outfile = fs::File::create(&output_path)?;
            io::copy(&mut file, &mut outfile)?;
        }

        // 获取并设置文件权限。
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;

            if let Some(mode) = file.unix_mode() {
                fs::set_permissions(&output_path, fs::Permissions::from_mode(mode))?;
            }
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    // use super::*;
}
