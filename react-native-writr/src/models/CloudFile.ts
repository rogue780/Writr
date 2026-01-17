import {CloudFile} from '../types';

export class CloudFileFactory {
  /**
   * Create a cloud file entry
   */
  static create(
    id: string,
    name: string,
    path: string,
    isDirectory: boolean,
    size?: number,
    modifiedTime?: string,
    mimeType?: string,
  ): CloudFile {
    const file: CloudFile = {
      id,
      name,
      path,
      isDirectory,
      size,
      modifiedTime,
      mimeType,
    };

    // Set isScrivenerProject flag
    if (isDirectory && name.endsWith('.scriv')) {
      file.isScrivenerProject = true;
    }

    return file;
  }

  /**
   * Check if this is a Scrivener project folder
   */
  static isScrivenerProject(file: CloudFile): boolean {
    return file.isDirectory && file.name.endsWith('.scriv');
  }

  /**
   * Format file size as human-readable string
   */
  static formatSize(bytes?: number): string {
    if (!bytes) return '';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }
}
