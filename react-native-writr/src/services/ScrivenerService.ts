import RNFS from 'react-native-fs';
import {XMLParser, XMLBuilder} from 'fast-xml-parser';
import {ScrivenerProject, BinderItem, BinderItemType} from '../types';
import {ScrivenerProjectFactory} from '../models/ScrivenerProject';

/**
 * Service for managing Scrivener projects
 * Handles loading, saving, and manipulating .scriv projects
 */
export class ScrivenerService {
  private static instance: ScrivenerService;
  private xmlParser: XMLParser;
  private xmlBuilder: XMLBuilder;
  private error: string | null = null;

  private constructor() {
    this.xmlParser = new XMLParser({
      ignoreAttributes: false,
      attributeNamePrefix: '@_',
    });
    this.xmlBuilder = new XMLBuilder({
      ignoreAttributes: false,
      attributeNamePrefix: '@_',
      format: true,
    });
  }

  static getInstance(): ScrivenerService {
    if (!ScrivenerService.instance) {
      ScrivenerService.instance = new ScrivenerService();
    }
    return ScrivenerService.instance;
  }

  getError(): string | null {
    return this.error;
  }

  private setError(error: string | null): void {
    this.error = error;
  }

  /**
   * Load a Scrivener project from the file system
   */
  async loadProject(projectPath: string): Promise<ScrivenerProject | null> {
    try {
      // Find the .scrivx file
      const files = await RNFS.readDir(projectPath);
      const scrivxFile = files.find((file) => file.name.endsWith('.scrivx'));

      if (!scrivxFile) {
        throw new Error('No .scrivx file found in project directory');
      }

      // Read and parse the .scrivx XML file
      const xmlContent = await RNFS.readFile(scrivxFile.path, 'utf8');
      const parsedXML = this.xmlParser.parse(xmlContent);

      // Extract project data
      const projectName = scrivxFile.name.replace('.scrivx', '');
      const binderItems = this.parseBinderItems(
        parsedXML.ScrivenerProject?.Binder,
      );

      // Load text contents from Files/Data directory
      const textContents = await this.loadTextContents(projectPath);

      return {
        name: projectName,
        path: projectPath,
        binderItems,
        textContents,
        settings: ScrivenerProjectFactory.defaultSettings(),
      };
    } catch (error) {
      console.error('Error loading project:', error);
      return null;
    }
  }

  /**
   * Save a Scrivener project to the file system
   */
  async saveProject(project: ScrivenerProject): Promise<boolean> {
    try {
      // Ensure project directory exists
      const projectExists = await RNFS.exists(project.path);
      if (!projectExists) {
        await RNFS.mkdir(project.path);
      }

      // Ensure subdirectories exist
      const filesDir = `${project.path}/Files`;
      const dataDir = `${filesDir}/Data`;
      const docsDir = `${filesDir}/Docs`;

      await this.ensureDirectoryExists(filesDir);
      await this.ensureDirectoryExists(dataDir);
      await this.ensureDirectoryExists(docsDir);

      // Save text contents to Files/Data
      await this.saveTextContents(project.path, project.textContents);

      // Generate and save .scrivx XML file
      const xmlContent = this.generateScrivxXML(project);
      const scrivxPath = `${project.path}/${project.name}.scrivx`;
      await RNFS.writeFile(scrivxPath, xmlContent, 'utf8');

      return true;
    } catch (error) {
      console.error('Error saving project:', error);
      return false;
    }
  }

  /**
   * Create a new Scrivener project
   */
  async createProject(
    name: string,
    parentDirectory: string,
  ): Promise<ScrivenerProject | null> {
    try {
      const projectPath = `${parentDirectory}/${name}.scriv`;

      // Create project directory
      await RNFS.mkdir(projectPath);

      // Create empty project
      const project = ScrivenerProjectFactory.createEmpty(name, projectPath);

      // Save initial project structure
      await this.saveProject(project);

      return project;
    } catch (error) {
      console.error('Error creating project:', error);
      return null;
    }
  }

  /**
   * Update text content for a binder item
   */
  updateTextContent(
    project: ScrivenerProject,
    itemId: string,
    content: string,
  ): ScrivenerProject {
    return {
      ...project,
      textContents: {
        ...project.textContents,
        [itemId]: content,
      },
    };
  }

  /**
   * Parse binder items from XML
   */
  private parseBinderItems(binderXML: any): BinderItem[] {
    if (!binderXML || !binderXML.BinderItem) {
      return [];
    }

    const items = Array.isArray(binderXML.BinderItem)
      ? binderXML.BinderItem
      : [binderXML.BinderItem];

    return items.map((item) => this.parseBinderItem(item));
  }

  /**
   * Parse a single binder item recursively
   */
  private parseBinderItem(itemXML: any): BinderItem {
    const id = itemXML['@_ID'] || '';
    const type = itemXML['@_Type'] || 'Text';
    const title = itemXML.Title || 'Untitled';

    const children: BinderItem[] = [];
    if (itemXML.Children && itemXML.Children.BinderItem) {
      const childItems = Array.isArray(itemXML.Children.BinderItem)
        ? itemXML.Children.BinderItem
        : [itemXML.Children.BinderItem];

      children.push(...childItems.map((child: any) => this.parseBinderItem(child)));
    }

    return {
      id: id.toString(),
      title: title.toString(),
      type: this.stringToBinderItemType(type),
      children,
    };
  }

  /**
   * Convert string to BinderItemType
   */
  private stringToBinderItemType(typeString: string): BinderItemType {
    const normalized = typeString.toLowerCase();
    switch (normalized) {
      case 'folder':
        return BinderItemType.FOLDER;
      case 'text':
        return BinderItemType.TEXT;
      case 'image':
        return BinderItemType.IMAGE;
      case 'pdf':
        return BinderItemType.PDF;
      case 'webarchive':
        return BinderItemType.WEB_ARCHIVE;
      default:
        return BinderItemType.TEXT;
    }
  }

  /**
   * Convert BinderItemType to string for XML
   */
  private binderItemTypeToString(type: BinderItemType): string {
    switch (type) {
      case BinderItemType.FOLDER:
        return 'Folder';
      case BinderItemType.TEXT:
        return 'Text';
      case BinderItemType.IMAGE:
        return 'Image';
      case BinderItemType.PDF:
        return 'PDF';
      case BinderItemType.WEB_ARCHIVE:
        return 'WebArchive';
    }
  }

  /**
   * Load text contents from Files/Data directory
   */
  private async loadTextContents(
    projectPath: string,
  ): Promise<Record<string, string>> {
    const textContents: Record<string, string> = {};
    const dataDir = `${projectPath}/Files/Data`;

    try {
      const exists = await RNFS.exists(dataDir);
      if (!exists) {
        return textContents;
      }

      const files = await RNFS.readDir(dataDir);

      for (const file of files) {
        if (file.name.endsWith('.rtf')) {
          const fileId = file.name.replace('.rtf', '');
          const content = await RNFS.readFile(file.path, 'utf8');
          textContents[fileId] = content;
        }
      }
    } catch (error) {
      console.error('Error loading text contents:', error);
    }

    return textContents;
  }

  /**
   * Save text contents to Files/Data directory
   */
  private async saveTextContents(
    projectPath: string,
    textContents: Record<string, string>,
  ): Promise<void> {
    const dataDir = `${projectPath}/Files/Data`;

    for (const [itemId, content] of Object.entries(textContents)) {
      const filePath = `${dataDir}/${itemId}.rtf`;
      await RNFS.writeFile(filePath, content, 'utf8');
    }
  }

  /**
   * Generate .scrivx XML content
   */
  private generateScrivxXML(project: ScrivenerProject): string {
    const xmlObject = {
      '?xml': {
        '@_version': '1.0',
        '@_encoding': 'UTF-8',
      },
      ScrivenerProject: {
        '@_Version': '2.0',
        '@_Identifier': project.path,
        Binder: {
          BinderItem: project.binderItems.map((item) =>
            this.binderItemToXML(item),
          ),
        },
      },
    };

    return this.xmlBuilder.build(xmlObject);
  }

  /**
   * Convert BinderItem to XML object recursively
   */
  private binderItemToXML(item: BinderItem): any {
    const xmlItem: any = {
      '@_ID': item.id,
      '@_Type': this.binderItemTypeToString(item.type),
      Title: item.title,
    };

    if (item.children && item.children.length > 0) {
      xmlItem.Children = {
        BinderItem: item.children.map((child) => this.binderItemToXML(child)),
      };
    }

    return xmlItem;
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
}

// Export a singleton instance
export default new ScrivenerService();
