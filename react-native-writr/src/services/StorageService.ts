import DocumentPicker from 'react-native-document-picker';
import RNFS from 'react-native-fs';

/**
 * Service for file system access and operations
 * Handles directory picking, file operations, and project directory management
 */
export class StorageService {
  /**
   * Pick a Scrivener project directory
   */
  async pickScrivenerProject(): Promise<string | null> {
    try {
      const result = await DocumentPicker.pick({
        type: [DocumentPicker.types.allFiles],
        copyTo: 'cachesDirectory',
      });

      if (result && result[0]) {
        const uri = result[0].uri;
        // Extract directory path
        const path = uri.replace('file://', '');
        const dirPath = path.substring(0, path.lastIndexOf('/'));

        // Validate it's a .scriv directory
        if (dirPath.endsWith('.scriv')) {
          return dirPath;
        }

        // Check if parent is .scriv
        const parentPath = dirPath.substring(0, dirPath.lastIndexOf('/'));
        if (parentPath.endsWith('.scriv')) {
          return parentPath;
        }

        throw new Error('Selected directory is not a Scrivener project');
      }

      return null;
    } catch (error) {
      if (DocumentPicker.isCancel(error)) {
        return null;
      }
      console.error('Error picking project:', error);
      return null;
    }
  }

  /**
   * Pick a directory for creating a new project
   */
  async pickDirectoryForNewProject(): Promise<string | null> {
    try {
      // On Android/iOS, we'll use the Documents directory
      // In a full implementation, you might want to use a directory picker
      return RNFS.DocumentDirectoryPath;
    } catch (error) {
      console.error('Error picking directory:', error);
      return null;
    }
  }

  /**
   * Copy project to cache for better performance
   */
  async copyProjectToCache(projectPath: string): Promise<string | null> {
    try {
      const projectName = projectPath.substring(
        projectPath.lastIndexOf('/') + 1,
      );
      const cachePath = `${RNFS.CachesDirectoryPath}/${projectName}`;

      // Check if already cached
      const cacheExists = await RNFS.exists(cachePath);
      if (cacheExists) {
        return cachePath;
      }

      // Copy project to cache
      await this.copyDirectory(projectPath, cachePath);

      return cachePath;
    } catch (error) {
      console.error('Error copying project to cache:', error);
      return null;
    }
  }

  /**
   * Copy directory recursively
   */
  private async copyDirectory(source: string, destination: string): Promise<void> {
    // Create destination directory
    await RNFS.mkdir(destination);

    // Read source directory
    const items = await RNFS.readDir(source);

    for (const item of items) {
      const destPath = `${destination}/${item.name}`;

      if (item.isDirectory()) {
        await this.copyDirectory(item.path, destPath);
      } else {
        await RNFS.copyFile(item.path, destPath);
      }
    }
  }

  /**
   * Get project directory path from project path
   */
  getProjectDirectory(projectPath: string): string {
    return projectPath.substring(0, projectPath.lastIndexOf('/'));
  }

  /**
   * Check if path exists
   */
  async exists(path: string): Promise<boolean> {
    try {
      return await RNFS.exists(path);
    } catch (error) {
      return false;
    }
  }

  /**
   * List directory contents
   */
  async listDirectory(path: string): Promise<RNFS.ReadDirItem[]> {
    try {
      return await RNFS.readDir(path);
    } catch (error) {
      console.error('Error listing directory:', error);
      return [];
    }
  }

  /**
   * Delete directory recursively
   */
  async deleteDirectory(path: string): Promise<boolean> {
    try {
      await RNFS.unlink(path);
      return true;
    } catch (error) {
      console.error('Error deleting directory:', error);
      return false;
    }
  }
}

// Export a singleton instance
export default new StorageService();
