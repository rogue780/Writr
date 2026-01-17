import {createSlice, PayloadAction} from '@reduxjs/toolkit';
import {ScrivenerProject, BinderItem} from '../../types';
import {ScrivenerProjectFactory} from '../../models/ScrivenerProject';

interface ProjectState {
  currentProject: ScrivenerProject | null;
  selectedItemId: string | null;
  isLoading: boolean;
  hasUnsavedChanges: boolean;
  error: string | null;
}

const initialState: ProjectState = {
  currentProject: null,
  selectedItemId: null,
  isLoading: false,
  hasUnsavedChanges: false,
  error: null,
};

const projectSlice = createSlice({
  name: 'project',
  initialState,
  reducers: {
    setProject: (state, action: PayloadAction<ScrivenerProject>) => {
      state.currentProject = action.payload;
      state.hasUnsavedChanges = false;
      state.error = null;
    },
    clearProject: (state) => {
      state.currentProject = null;
      state.selectedItemId = null;
      state.hasUnsavedChanges = false;
    },
    selectItem: (state, action: PayloadAction<string>) => {
      state.selectedItemId = action.payload;
    },
    updateTextContent: (
      state,
      action: PayloadAction<{itemId: string; content: string}>,
    ) => {
      if (state.currentProject) {
        state.currentProject.textContents[action.payload.itemId] =
          action.payload.content;
        state.hasUnsavedChanges = true;
      }
    },
    addBinderItem: (
      state,
      action: PayloadAction<{item: BinderItem; parentId?: string}>,
    ) => {
      if (state.currentProject) {
        state.currentProject = ScrivenerProjectFactory.addBinderItem(
          state.currentProject,
          action.payload.item,
          action.payload.parentId,
        );
        state.hasUnsavedChanges = true;
      }
    },
    renameBinderItem: (
      state,
      action: PayloadAction<{id: string; newTitle: string}>,
    ) => {
      if (state.currentProject) {
        state.currentProject = ScrivenerProjectFactory.renameBinderItem(
          state.currentProject,
          action.payload.id,
          action.payload.newTitle,
        );
        state.hasUnsavedChanges = true;
      }
    },
    deleteBinderItem: (state, action: PayloadAction<string>) => {
      if (state.currentProject) {
        state.currentProject = ScrivenerProjectFactory.deleteBinderItem(
          state.currentProject,
          action.payload,
        );
        if (state.selectedItemId === action.payload) {
          state.selectedItemId = null;
        }
        state.hasUnsavedChanges = true;
      }
    },
    markAsSaved: (state) => {
      state.hasUnsavedChanges = false;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.isLoading = action.payload;
    },
    setError: (state, action: PayloadAction<string | null>) => {
      state.error = action.payload;
    },
  },
});

export const {
  setProject,
  clearProject,
  selectItem,
  updateTextContent,
  addBinderItem,
  renameBinderItem,
  deleteBinderItem,
  markAsSaved,
  setLoading,
  setError,
} = projectSlice.actions;

export default projectSlice.reducer;
