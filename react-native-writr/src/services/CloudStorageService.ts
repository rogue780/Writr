import {CloudProvider, CloudProviderType, CloudFile} from '../types';
import {GoogleDriveProvider} from './CloudProviders/GoogleDriveProvider';

/**
 * Service for managing cloud storage providers
 * Provides a unified interface for different cloud storage services
 */
export class CloudStorageService {
  private currentProvider: CloudProvider | null = null;
  private providers: Map<CloudProviderType, CloudProvider>;

  constructor() {
    this.providers = new Map();
    this.providers.set(
      CloudProviderType.GOOGLE_DRIVE,
      new GoogleDriveProvider(),
    );
    // Add other providers here:
    // this.providers.set(CloudProviderType.DROPBOX, new DropboxProvider());
    // this.providers.set(CloudProviderType.ONEDRIVE, new OneDriveProvider());
  }

  /**
   * Get available cloud providers
   */
  getAvailableProviders(): CloudProviderType[] {
    return Array.from(this.providers.keys());
  }

  /**
   * Select and sign in to a provider
   */
  async selectProvider(
    providerType: CloudProviderType,
  ): Promise<boolean> {
    const provider = this.providers.get(providerType);
    if (!provider) {
      throw new Error(`Provider ${providerType} not found`);
    }

    const success = await provider.signIn();
    if (success) {
      this.currentProvider = provider;
    }

    return success;
  }

  /**
   * Sign out from current provider
   */
  async signOut(): Promise<void> {
    if (this.currentProvider) {
      await this.currentProvider.signOut();
      this.currentProvider = null;
    }
  }

  /**
   * Get current provider
   */
  getCurrentProvider(): CloudProvider | null {
    return this.currentProvider;
  }

  /**
   * Check if signed in
   */
  isSignedIn(): boolean {
    return this.currentProvider?.isSignedIn ?? false;
  }

  /**
   * List files in current provider
   */
  async listFiles(folderId?: string): Promise<CloudFile[]> {
    if (!this.currentProvider) {
      throw new Error('No provider selected');
    }

    return await this.currentProvider.listFiles(folderId);
  }

  /**
   * Download file from current provider
   */
  async downloadFile(
    fileId: string,
    destinationPath: string,
  ): Promise<boolean> {
    if (!this.currentProvider) {
      throw new Error('No provider selected');
    }

    return await this.currentProvider.downloadFile(fileId, destinationPath);
  }

  /**
   * Upload file to current provider
   */
  async uploadFile(
    localPath: string,
    fileName: string,
    parentFolderId?: string,
  ): Promise<string | null> {
    if (!this.currentProvider) {
      throw new Error('No provider selected');
    }

    return await this.currentProvider.uploadFile(
      localPath,
      fileName,
      parentFolderId,
    );
  }

  /**
   * Create folder in current provider
   */
  async createFolder(
    name: string,
    parentFolderId?: string,
  ): Promise<CloudFile | null> {
    if (!this.currentProvider) {
      throw new Error('No provider selected');
    }

    return await this.currentProvider.createFolder(name, parentFolderId);
  }

  /**
   * Delete file from current provider
   */
  async deleteFile(fileId: string): Promise<boolean> {
    if (!this.currentProvider) {
      throw new Error('No provider selected');
    }

    return await this.currentProvider.deleteFile(fileId);
  }

  /**
   * Search files in current provider
   */
  async search(query: string): Promise<CloudFile[]> {
    if (!this.currentProvider) {
      throw new Error('No provider selected');
    }

    return await this.currentProvider.search(query);
  }
}

// Export a singleton instance
export default new CloudStorageService();
