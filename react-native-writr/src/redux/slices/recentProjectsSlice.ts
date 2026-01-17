import {createSlice, PayloadAction, createAsyncThunk} from '@reduxjs/toolkit';
import {RecentProject} from '../../types';
import RecentProjectsService from '../../services/RecentProjectsService';

interface RecentProjectsState {
  projects: RecentProject[];
  isLoading: boolean;
}

const initialState: RecentProjectsState = {
  projects: [],
  isLoading: false,
};

// Async thunks
export const loadRecentProjects = createAsyncThunk(
  'recentProjects/load',
  async () => {
    return await RecentProjectsService.loadRecentProjects();
  },
);

export const addRecentProject = createAsyncThunk(
  'recentProjects/add',
  async ({name, path}: {name: string; path: string}) => {
    await RecentProjectsService.addRecentProject(name, path);
    return await RecentProjectsService.loadRecentProjects();
  },
);

export const removeRecentProject = createAsyncThunk(
  'recentProjects/remove',
  async (path: string) => {
    await RecentProjectsService.removeRecentProject(path);
    return await RecentProjectsService.loadRecentProjects();
  },
);

export const clearRecentProjects = createAsyncThunk(
  'recentProjects/clear',
  async () => {
    await RecentProjectsService.clearRecentProjects();
    return [];
  },
);

const recentProjectsSlice = createSlice({
  name: 'recentProjects',
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(loadRecentProjects.pending, (state) => {
        state.isLoading = true;
      })
      .addCase(loadRecentProjects.fulfilled, (state, action) => {
        state.projects = action.payload;
        state.isLoading = false;
      })
      .addCase(addRecentProject.fulfilled, (state, action) => {
        state.projects = action.payload;
      })
      .addCase(removeRecentProject.fulfilled, (state, action) => {
        state.projects = action.payload;
      })
      .addCase(clearRecentProjects.fulfilled, (state, action) => {
        state.projects = action.payload;
      });
  },
});

export default recentProjectsSlice.reducer;
