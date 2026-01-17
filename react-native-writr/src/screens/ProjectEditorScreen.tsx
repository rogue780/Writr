import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { useAppSelector, useAppDispatch } from '../redux/hooks';
import { setSelectedItem, setUnsavedChanges } from '../redux/slices/projectSlice';
import { BinderTreeView } from '../components/BinderTreeView';
import { DocumentEditor } from '../components/DocumentEditor';
import { ScrivenerService } from '../services/ScrivenerService';
import { BinderItem } from '../types';

interface ProjectEditorScreenProps {
  navigation: any;
}

export const ProjectEditorScreen: React.FC<ProjectEditorScreenProps> = ({ navigation }) => {
  const dispatch = useAppDispatch();
  const currentProject = useAppSelector((state) => state.project.currentProject);
  const selectedItem = useAppSelector((state) => state.project.selectedItem);
  const hasUnsavedChanges = useAppSelector((state) => state.project.hasUnsavedChanges);

  const [showBinder, setShowBinder] = useState(true);
  const [saving, setSaving] = useState(false);

  const scrivenerService = ScrivenerService.getInstance();

  const handleItemSelected = (itemId: string) => {
    // Find the item by ID
    const findItem = (items: BinderItem[]): BinderItem | null => {
      for (const item of items) {
        if (item.id === itemId) return item;
        if (item.children.length > 0) {
          const found = findItem(item.children);
          if (found) return found;
        }
      }
      return null;
    };

    if (currentProject) {
      const item = findItem(currentProject.binderItems);
      if (item) {
        dispatch(setSelectedItem(item));
      }
    }
  };

  const handleContentChanged = (content: string) => {
    if (currentProject && selectedItem) {
      scrivenerService.updateTextContent(currentProject, selectedItem.id, content);
      dispatch(setUnsavedChanges(true));
    }
  };

  const handleAddItem = (parentId?: string) => {
    // TODO: Implement add item functionality
    Alert.alert('Add Item', 'Add item functionality not yet implemented');
  };

  const handleRenameItem = (itemId: string) => {
    // TODO: Implement rename item functionality
    Alert.alert('Rename Item', 'Rename item functionality not yet implemented');
  };

  const handleDeleteItem = (itemId: string) => {
    // TODO: Implement delete item functionality
    Alert.alert('Delete Item', 'Delete item functionality not yet implemented');
  };

  const handleSaveProject = async () => {
    if (!currentProject) return;

    setSaving(true);

    try {
      await scrivenerService.saveProject(currentProject);
      dispatch(setUnsavedChanges(false));
      setSaving(false);
      Alert.alert('Success', 'Project saved successfully');
    } catch (error) {
      setSaving(false);
      Alert.alert('Error', `Error saving: ${error}`);
    }
  };

  React.useEffect(() => {
    navigation.setOptions({
      headerTitle: () => (
        <View style={styles.headerTitle}>
          <Text style={styles.headerTitleText}>
            {currentProject?.name || 'Project'}
          </Text>
          {hasUnsavedChanges && (
            <View style={styles.unsavedIndicator} />
          )}
        </View>
      ),
      headerRight: () => (
        <View style={styles.headerButtons}>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => setShowBinder(!showBinder)}
          >
            <Icon
              name={showBinder ? 'menu-open' : 'menu'}
              size={24}
              color="#FFFFFF"
            />
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={handleSaveProject}
            disabled={saving}
          >
            {saving ? (
              <ActivityIndicator size="small" color="#FFFFFF" />
            ) : (
              <Icon name="save" size={24} color="#FFFFFF" />
            )}
          </TouchableOpacity>
        </View>
      ),
    });
  }, [navigation, currentProject, hasUnsavedChanges, showBinder, saving]);

  if (!currentProject) {
    return (
      <View style={styles.emptyContainer}>
        <Text style={styles.emptyText}>No project loaded</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.editorContainer}>
        {showBinder && (
          <>
            <View style={styles.binderContainer}>
              <BinderTreeView
                items={currentProject.binderItems}
                selectedId={selectedItem?.id}
                onSelectItem={handleItemSelected}
                onAddItem={handleAddItem}
                onRenameItem={handleRenameItem}
                onDeleteItem={handleDeleteItem}
              />
            </View>
            <View style={styles.divider} />
          </>
        )}
        <View style={styles.documentContainer}>
          {selectedItem ? (
            <DocumentEditor
              item={selectedItem}
              content={currentProject.textContents[selectedItem.id] || ''}
              onContentChange={handleContentChanged}
              hasUnsavedChanges={hasUnsavedChanges}
            />
          ) : (
            <View style={styles.noSelectionContainer}>
              <Text style={styles.noSelectionText}>
                Select a document from the binder
              </Text>
            </View>
          )}
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  headerTitle: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerTitleText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  unsavedIndicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#FF9800',
    marginLeft: 8,
  },
  headerButtons: {
    flexDirection: 'row',
    alignItems: 'center',
    marginRight: 8,
  },
  headerButton: {
    padding: 8,
    marginLeft: 8,
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyText: {
    fontSize: 16,
    color: '#757575',
  },
  editorContainer: {
    flex: 1,
    flexDirection: 'row',
  },
  binderContainer: {
    width: 250,
    backgroundColor: '#F5F5F5',
  },
  divider: {
    width: 1,
    backgroundColor: '#E0E0E0',
  },
  documentContainer: {
    flex: 1,
  },
  noSelectionContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  noSelectionText: {
    fontSize: 16,
    color: '#757575',
  },
});
