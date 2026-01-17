import RNFS from 'react-native-fs';
import {CloudFile, SyncProgress} from '../types';
import CloudStorageService from './CloudStorageService';

/**
 * Service for syncing Scrivener projects between cloud and local storage
 * Handles recursive upload/download of project directories
 */
export class CloudSyncService {
  private cloudStorageService: typeof CloudStorageService;
  private onProgress?: (progress: SyncProgress) => void;

  constructor(cloudStorageService: typeof CloudStorageService) {
    this.cloudStorageService = cloudStorageService;
  }

  /**
   * Set progress callback
   */
  setProgressCallback(callback: (progress: SyncProgress) => void): void {
    this.onProgress = callback;
  }

  /**
   * Download a Scrivener project from cloud to local storage
   */
  async downloadProject(
    projectFolder: CloudFile,
  ): Promise<string | null> {
    try {
      // Create local directory for cloud projects
      const localDir = `${RNFS.DocumentDirectoryPath}/CloudProjects`;
      await this.ensureDirectoryExists(localDir);

      const projectDir = `${localDir}/${projectFolder.name}`;

      // Download all files recursively
      await this.downloadFolderRecursively(
        projectFolder.id,
        projectFolder.name,
        projectDir,
      );

      return projectDir;
    } catch (error) {
      console.error('Error downloading project:', error);
      return null;
    }
  }

  /**
   * Upload a Scrivener project from local to cloud storage
   */
  async uploadProject(
    localProjectPath: string,
    cloudParentFolderId?: string,
  ): Promise<boolean> {
    try {
      const projectName = localProjectPath.substring(
        localProjectPath.lastIndexOf('/') + 1,
      );

      // Create project folder in cloud
      const cloudProjectFolder = await this.cloudStorageService.createFolder(
        projectName,
        cloudParentFolderId,
      );

      if (!cloudProjectFolder) {
        throw new Error('Failed to create project folder in cloud');
      }

      // Upload all files recursively
      await this.uploadFolderRecursively(
        localProjectPath,
        cloudProjectFolder.id,
      );

      return true;
    } catch (error) {
      console.error('Error uploading project:', error);
      return false;
    }
  }

  /**
   * Download a folder recursively
   */
  private async downloadFolderRecursively(
    cloudFolderId: string,
    folderName: string,
    localPath: string,
  ): Promise<void> {
    // Create local directory
    await this.ensureDirectoryExists(localPath);

    // List files in cloud folder
    const files = await this.cloudStorageService.listFiles(cloudFolderId);

    let processed = 0;
    const total = files.length;

    for (const file of files) {
      this.reportProgress(processed, total, `Downloading ${file.name}...`);

      if (file.isDirectory) {
        // Recursively download subfolder
        const subfolderPath = `${localPath}/${file.name}`;
        await this.downloadFolderRecursively(
          file.id,
          file.name,
          subfolderPath,
        );
      } else {
        // Download file
        const filePath = `${localPath}/${file.name}`;
        await this.cloudStorageService.downloadFile(file.id, filePath);
      }

      processed++;
    }

    this.reportProgress(total, total, `Downloaded ${folderName}`);
  }

  /**
   * Upload a folder recursively
   */
  private async uploadFolderRecursively(
    localPath: string,
    cloudParentFolderId: string,
  ): Promise<void> {
    const items = await RNFS.readDir(localPath);

    let processed = 0;
    const total = items.length;

    for (const item of items) {
      this.reportProgress(processed, total, `Uploading ${item.name}...`);

      if (item.isDirectory()) {
        // Create subfolder in cloud
        const cloudSubfolder = await this.cloudStorageService.createFolder(
          item.name,
          cloudParentFolderId,
        );

        if (cloudSubfolder) {
          // Recursively upload subfolder contents
          await this.uploadFolderRecursively(item.path, cloudSubfolder.id);
        }
      } else {
        // Upload file
        await this.cloudStorageService.uploadFile(
          item.path,
          item.name,
          cloudParentFolderId,
        );
      }

      processed++;
    }

    this.reportProgress(total, total, 'Upload complete');
  }

  /**
   * Ensure directory exists, create if not
   */
  private async ensureDirectoryExists(path: string): Promise<void> {
    const exists = await RNFS.exists(path);
    if (!exists) {
      await RNFS.mkdir(path);
    }
  }

  /**
   * Report progress
   */
  private reportProgress(
    current: number,
    total: number,
    message: string,
  ): void {
    if (this.onProgress) {
      this.onProgress({current, total, message});
    }
  }
}

// Export a singleton instance
export default new CloudSyncService(CloudStorageService);
