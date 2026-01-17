import {formatDistanceToNow} from 'date-fns';
import {RecentProject} from '../types';

export class RecentProjectFactory {
  /**
   * Create a recent project entry
   */
  static create(name: string, path: string): RecentProject {
    return {
      name,
      path,
      lastOpened: Date.now(),
    };
  }

  /**
   * Format the last opened time as relative time (e.g., "2 hours ago")
   */
  static getRelativeTime(project: RecentProject): string {
    return formatDistanceToNow(project.lastOpened, {addSuffix: true});
  }

  /**
   * Convert to JSON for storage
   */
  static toJSON(project: RecentProject): string {
    return JSON.stringify(project);
  }

  /**
   * Parse from JSON
   */
  static fromJSON(json: string): RecentProject {
    return JSON.parse(json);
  }

  /**
   * Sort recent projects by last opened (most recent first)
   */
  static sortByLastOpened(projects: RecentProject[]): RecentProject[] {
    return [...projects].sort((a, b) => b.lastOpened - a.lastOpened);
  }
}
