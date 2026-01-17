import {GoogleSignin} from '@react-native-google-signin/google-signin';
import axios from 'axios';
import {CloudProvider, CloudFile} from '../../types';
import {CloudFileFactory} from '../../models/CloudFile';
import RNFS from 'react-native-fs';

/**
 * Google Drive cloud storage provider
 * Uses Google Sign-In and Google Drive API v3
 */
export class GoogleDriveProvider implements CloudProvider {
  name = 'Google Drive';
  isSignedIn = false;
  private accessToken: string | null = null;
  private baseUrl = 'https://www.googleapis.com/drive/v3';

  constructor() {
    // Configure Google Sign In
    GoogleSignin.configure({
      scopes: ['https://www.googleapis.com/auth/drive.file'],
      webClientId: 'YOUR_WEB_CLIENT_ID', // Replace with actual Web Client ID
    });
  }

  /**
   * Sign in to Google Drive
   */
  async signIn(): Promise<boolean> {
    try {
      await GoogleSignin.hasPlayServices();
      const userInfo = await GoogleSignin.signIn();
      const tokens = await GoogleSignin.getTokens();

      this.accessToken = tokens.accessToken;
      this.isSignedIn = true;

      return true;
    } catch (error) {
      console.error('Google Sign-In error:', error);
      return false;
    }
  }

  /**
   * Sign out from Google Drive
   */
  async signOut(): Promise<void> {
    try {
      await GoogleSignin.revokeAccess();
      await GoogleSignin.signOut();
      this.accessToken = null;
      this.isSignedIn = false;
    } catch (error) {
      console.error('Google Sign-Out error:', error);
    }
  }

  /**
   * List files in a folder
   */
  async listFiles(folderId?: string): Promise<CloudFile[]> {
    if (!this.accessToken) {
      throw new Error('Not signed in');
    }

    try {
      const query = folderId
        ? `'${folderId}' in parents and trashed=false`
        : `'root' in parents and trashed=false`;

      const response = await axios.get(`${this.baseUrl}/files`, {
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
        },
        params: {
          q: query,
          fields:
            'files(id, name, mimeType, size, modifiedTime, parents)',
          orderBy: 'folder,name',
        },
      });

      return response.data.files.map((file: any) =>
        CloudFileFactory.create(
          file.id,
          file.name,
          file.name,
          file.mimeType === 'application/vnd.google-apps.folder',
          file.size ? parseInt(file.size, 10) : undefined,
          file.modifiedTime,
          file.mimeType,
        ),
      );
    } catch (error) {
      console.error('Error listing files:', error);
      return [];
    }
  }

  /**
   * Download a file
   */
  async downloadFile(
    fileId: string,
    destinationPath: string,
  ): Promise<boolean> {
    if (!this.accessToken) {
      throw new Error('Not signed in');
    }

    try {
      const response = await axios.get(
        `${this.baseUrl}/files/${fileId}?alt=media`,
        {
          headers: {
            Authorization: `Bearer ${this.accessToken}`,
          },
          responseType: 'arraybuffer',
        },
      );

      await RNFS.writeFile(
        destinationPath,
        Buffer.from(response.data).toString('base64'),
        'base64',
      );

      return true;
    } catch (error) {
      console.error('Error downloading file:', error);
      return false;
    }
  }

  /**
   * Upload a file
   */
  async uploadFile(
    localPath: string,
    fileName: string,
    parentFolderId?: string,
  ): Promise<string | null> {
    if (!this.accessToken) {
      throw new Error('Not signed in');
    }

    try {
      // Read file content
      const fileContent = await RNFS.readFile(localPath, 'base64');

      // Create metadata
      const metadata = {
        name: fileName,
        parents: parentFolderId ? [parentFolderId] : ['root'],
      };

      // Upload file (simplified - in production use multipart upload)
      const response = await axios.post(
        `${this.baseUrl}/files`,
        {
          ...metadata,
          data: fileContent,
        },
        {
          headers: {
            Authorization: `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json',
          },
        },
      );

      return response.data.id;
    } catch (error) {
      console.error('Error uploading file:', error);
      return null;
    }
  }

  /**
   * Create a folder
   */
  async createFolder(
    name: string,
    parentFolderId?: string,
  ): Promise<CloudFile | null> {
    if (!this.accessToken) {
      throw new Error('Not signed in');
    }

    try {
      const metadata = {
        name,
        mimeType: 'application/vnd.google-apps.folder',
        parents: parentFolderId ? [parentFolderId] : ['root'],
      };

      const response = await axios.post(`${this.baseUrl}/files`, metadata, {
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
          'Content-Type': 'application/json',
        },
        params: {
          fields: 'id, name, mimeType',
        },
      });

      return CloudFileFactory.create(
        response.data.id,
        response.data.name,
        response.data.name,
        true,
        undefined,
        undefined,
        response.data.mimeType,
      );
    } catch (error) {
      console.error('Error creating folder:', error);
      return null;
    }
  }

  /**
   * Delete a file
   */
  async deleteFile(fileId: string): Promise<boolean> {
    if (!this.accessToken) {
      throw new Error('Not signed in');
    }

    try {
      await axios.delete(`${this.baseUrl}/files/${fileId}`, {
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
        },
      });

      return true;
    } catch (error) {
      console.error('Error deleting file:', error);
      return false;
    }
  }

  /**
   * Search for files
   */
  async search(query: string): Promise<CloudFile[]> {
    if (!this.accessToken) {
      throw new Error('Not signed in');
    }

    try {
      const searchQuery = `name contains '${query}' and trashed=false`;

      const response = await axios.get(`${this.baseUrl}/files`, {
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
        },
        params: {
          q: searchQuery,
          fields:
            'files(id, name, mimeType, size, modifiedTime)',
          orderBy: 'name',
        },
      });

      return response.data.files.map((file: any) =>
        CloudFileFactory.create(
          file.id,
          file.name,
          file.name,
          file.mimeType === 'application/vnd.google-apps.folder',
          file.size ? parseInt(file.size, 10) : undefined,
          file.modifiedTime,
          file.mimeType,
        ),
      );
    } catch (error) {
      console.error('Error searching files:', error);
      return [];
    }
  }
}
