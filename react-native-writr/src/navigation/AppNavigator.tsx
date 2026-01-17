import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { HomeScreen } from '../screens/HomeScreen';
import { ProjectEditorScreen } from '../screens/ProjectEditorScreen';
import { CloudBrowserScreen } from '../screens/CloudBrowserScreen';

export type RootStackParamList = {
  Home: undefined;
  ProjectEditor: undefined;
  CloudBrowser: {
    onProjectSelect?: (project: any) => void;
  };
};

const Stack = createStackNavigator<RootStackParamList>();

export const AppNavigator: React.FC = () => {
  return (
    <NavigationContainer>
      <Stack.Navigator
        initialRouteName="Home"
        screenOptions={{
          headerStyle: {
            backgroundColor: '#673AB7',
          },
          headerTintColor: '#FFFFFF',
          headerTitleStyle: {
            fontWeight: 'bold',
          },
        }}
      >
        <Stack.Screen
          name="Home"
          component={HomeScreen}
          options={{
            title: 'Writr',
          }}
        />
        <Stack.Screen
          name="ProjectEditor"
          component={ProjectEditorScreen}
          options={{
            title: 'Editor',
          }}
        />
        <Stack.Screen
          name="CloudBrowser"
          component={CloudBrowserScreen}
          options={{
            title: 'Browse Cloud',
          }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
};
