// Core types for Writr React Native

export enum BinderItemType {
  FOLDER = 'folder',
  TEXT = 'text',
  IMAGE = 'image',
  PDF = 'pdf',
  WEB_ARCHIVE = 'webArchive',
}

export interface BinderItem {
  id: string;
  title: string;
  type: BinderItemType;
  children: BinderItem[];
  label?: string;
  status?: string;
}

export interface ProjectSettings {
  autoSave: boolean;
  autoSaveInterval: number;
  defaultTextFormat: string;
}

export interface ScrivenerProject {
  name: string;
  path: string;
  binderItems: BinderItem[];
  textContents: Record<string, string>;
  settings: ProjectSettings;
}

export interface RecentProject {
  name: string;
  path: string;
  lastOpened: number;
}

export interface CloudFile {
  id: string;
  name: string;
  path: string;
  isDirectory: boolean;
  isScrivenerProject?: boolean;
  size?: number;
  modifiedTime?: string;
  mimeType?: string;
}

export interface CloudProvider {
  name: string;
  isSignedIn: boolean;
  signIn: () => Promise<boolean>;
  signOut: () => Promise<void>;
  listFiles: (folderId?: string) => Promise<CloudFile[]>;
  downloadFile: (fileId: string, destinationPath: string) => Promise<boolean>;
  uploadFile: (localPath: string, fileName: string, parentFolderId?: string) => Promise<string | null>;
  createFolder: (name: string, parentFolderId?: string) => Promise<CloudFile | null>;
  deleteFile: (fileId: string) => Promise<boolean>;
  search: (query: string) => Promise<CloudFile[]>;
}

export enum CloudProviderType {
  GOOGLE_DRIVE = 'google_drive',
  DROPBOX = 'dropbox',
  ONEDRIVE = 'onedrive',
}

export interface SyncProgress {
  current: number;
  total: number;
  message: string;
}
