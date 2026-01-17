import {configureStore} from '@reduxjs/toolkit';
import projectReducer from '../slices/projectSlice';
import recentProjectsReducer from '../slices/recentProjectsSlice';

export const store = configureStore({
  reducer: {
    project: projectReducer,
    recentProjects: recentProjectsReducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        // Ignore these action types
        ignoredActions: ['project/setProject'],
        // Ignore these field paths in all actions
        ignoredActionPaths: ['payload.timestamp'],
        // Ignore these paths in the state
        ignoredPaths: ['project.currentProject'],
      },
    }),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
