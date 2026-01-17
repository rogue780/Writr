import AsyncStorage from '@react-native-async-storage/async-storage';
import {RecentProject} from '../types';
import {RecentProjectFactory} from '../models/RecentProject';

const RECENT_PROJECTS_KEY = '@writr_recent_projects';
const MAX_RECENT_PROJECTS = 10;

/**
 * Service for managing recent projects
 * Uses AsyncStorage for persistence
 */
export class RecentProjectsService {
  /**
   * Load all recent projects
   */
  async loadRecentProjects(): Promise<RecentProject[]> {
    try {
      const data = await AsyncStorage.getItem(RECENT_PROJECTS_KEY);
      if (!data) {
        return [];
      }

      const projects: RecentProject[] = JSON.parse(data);
      return RecentProjectFactory.sortByLastOpened(projects);
    } catch (error) {
      console.error('Error loading recent projects:', error);
      return [];
    }
  }

  /**
   * Add or update a recent project
   */
  async addRecentProject(name: string, path: string): Promise<void> {
    try {
      const projects = await this.loadRecentProjects();

      // Remove existing entry if present
      const filtered = projects.filter((p) => p.path !== path);

      // Add new entry at the beginning
      const newProject = RecentProjectFactory.create(name, path);
      filtered.unshift(newProject);

      // Limit to MAX_RECENT_PROJECTS
      const limited = filtered.slice(0, MAX_RECENT_PROJECTS);

      await AsyncStorage.setItem(
        RECENT_PROJECTS_KEY,
        JSON.stringify(limited),
      );
    } catch (error) {
      console.error('Error adding recent project:', error);
    }
  }

  /**
   * Remove a project from recent list
   */
  async removeRecentProject(path: string): Promise<void> {
    try {
      const projects = await this.loadRecentProjects();
      const filtered = projects.filter((p) => p.path !== path);

      await AsyncStorage.setItem(
        RECENT_PROJECTS_KEY,
        JSON.stringify(filtered),
      );
    } catch (error) {
      console.error('Error removing recent project:', error);
    }
  }

  /**
   * Clear all recent projects
   */
  async clearRecentProjects(): Promise<void> {
    try {
      await AsyncStorage.removeItem(RECENT_PROJECTS_KEY);
    } catch (error) {
      console.error('Error clearing recent projects:', error);
    }
  }
}

// Export a singleton instance
export default new RecentProjectsService();
