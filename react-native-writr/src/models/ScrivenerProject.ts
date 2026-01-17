import {
  ScrivenerProject,
  BinderItem,
  BinderItemType,
  ProjectSettings,
} from '../types';

export class ScrivenerProjectFactory {
  /**
   * Create an empty Scrivener project with standard folder structure
   */
  static createEmpty(name: string, path: string): ScrivenerProject {
    const timestamp = Date.now();

    const manuscript: BinderItem = {
      id: `${timestamp}_manuscript`,
      title: 'Manuscript',
      type: BinderItemType.FOLDER,
      children: [],
    };

    const research: BinderItem = {
      id: `${timestamp}_research`,
      title: 'Research',
      type: BinderItemType.FOLDER,
      children: [],
    };

    const characters: BinderItem = {
      id: `${timestamp}_characters`,
      title: 'Characters',
      type: BinderItemType.FOLDER,
      children: [],
    };

    const places: BinderItem = {
      id: `${timestamp}_places`,
      title: 'Places',
      type: BinderItemType.FOLDER,
      children: [],
    };

    return {
      name,
      path,
      binderItems: [manuscript, research, characters, places],
      textContents: {},
      settings: this.defaultSettings(),
    };
  }

  /**
   * Get default project settings
   */
  static defaultSettings(): ProjectSettings {
    return {
      autoSave: true,
      autoSaveInterval: 300,
      defaultTextFormat: 'rtf',
    };
  }

  /**
   * Create a new binder item
   */
  static createBinderItem(
    title: string,
    type: BinderItemType = BinderItemType.TEXT,
  ): BinderItem {
    return {
      id: `${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      title,
      type,
      children: [],
    };
  }

  /**
   * Find a binder item by ID recursively
   */
  static findBinderItemById(
    items: BinderItem[],
    id: string,
  ): BinderItem | null {
    for (const item of items) {
      if (item.id === id) {
        return item;
      }
      if (item.children.length > 0) {
        const found = this.findBinderItemById(item.children, id);
        if (found) {
          return found;
        }
      }
    }
    return null;
  }

  /**
   * Add a binder item to parent (or root if no parent)
   */
  static addBinderItem(
    project: ScrivenerProject,
    item: BinderItem,
    parentId?: string,
  ): ScrivenerProject {
    const newBinderItems = [...project.binderItems];

    if (!parentId) {
      // Add to root
      newBinderItems.push(item);
    } else {
      // Add to parent
      const addToParent = (items: BinderItem[]): BinderItem[] => {
        return items.map((currentItem) => {
          if (currentItem.id === parentId) {
            return {
              ...currentItem,
              children: [...currentItem.children, item],
            };
          }
          if (currentItem.children.length > 0) {
            return {
              ...currentItem,
              children: addToParent(currentItem.children),
            };
          }
          return currentItem;
        });
      };

      return {
        ...project,
        binderItems: addToParent(newBinderItems),
      };
    }

    return {
      ...project,
      binderItems: newBinderItems,
    };
  }

  /**
   * Rename a binder item
   */
  static renameBinderItem(
    project: ScrivenerProject,
    id: string,
    newTitle: string,
  ): ScrivenerProject {
    const renameItem = (items: BinderItem[]): BinderItem[] => {
      return items.map((item) => {
        if (item.id === id) {
          return {...item, title: newTitle};
        }
        if (item.children.length > 0) {
          return {...item, children: renameItem(item.children)};
        }
        return item;
      });
    };

    return {
      ...project,
      binderItems: renameItem(project.binderItems),
    };
  }

  /**
   * Delete a binder item
   */
  static deleteBinderItem(
    project: ScrivenerProject,
    id: string,
  ): ScrivenerProject {
    const deleteItem = (items: BinderItem[]): BinderItem[] => {
      return items
        .filter((item) => item.id !== id)
        .map((item) => {
          if (item.children.length > 0) {
            return {...item, children: deleteItem(item.children)};
          }
          return item;
        });
    };

    // Also remove text content if exists
    const newTextContents = {...project.textContents};
    delete newTextContents[id];

    return {
      ...project,
      binderItems: deleteItem(project.binderItems),
      textContents: newTextContents,
    };
  }
}
