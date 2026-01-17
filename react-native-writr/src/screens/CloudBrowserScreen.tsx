import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  TextInput,
  Modal,
  ScrollView,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { CloudStorageService } from '../services/CloudStorageService';
import { CloudFile } from '../types';

interface CloudBrowserScreenProps {
  navigation: any;
  route: {
    params?: {
      onProjectSelect?: (project: CloudFile) => void;
    };
  };
}

export const CloudBrowserScreen: React.FC<CloudBrowserScreenProps> = ({
  navigation,
  route,
}) => {
  const [breadcrumbs, setBreadcrumbs] = useState<Array<CloudFile | null>>([null]);
  const [currentFiles, setCurrentFiles] = useState<CloudFile[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [newProjectName, setNewProjectName] = useState('');

  const cloudService = CloudStorageService.getInstance();

  useEffect(() => {
    loadFiles();
  }, [breadcrumbs]);

  useEffect(() => {
    const providerName = cloudService.getCurrentProvider()?.name || 'Cloud';
    navigation.setOptions({
      title: `Browse ${providerName}`,
      headerRight: () => (
        <View style={styles.headerButtons}>
          <TouchableOpacity style={styles.headerButton} onPress={loadFiles}>
            <Icon name="refresh" size={24} color="#FFFFFF" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.headerButton} onPress={handleSignOut}>
            <Icon name="logout" size={24} color="#FFFFFF" />
          </TouchableOpacity>
        </View>
      ),
    });
  }, [navigation]);

  const loadFiles = async () => {
    setIsLoading(true);

    try {
      const folderId = breadcrumbs[breadcrumbs.length - 1]?.id;
      const files = await cloudService.listFiles(folderId);
      setCurrentFiles(files);
      setIsLoading(false);
    } catch (error) {
      setIsLoading(false);
      Alert.alert('Error', `Failed to load files: ${error}`);
    }
  };

  const navigateToFolder = (folder: CloudFile) => {
    setBreadcrumbs([...breadcrumbs, folder]);
  };

  const navigateBack = () => {
    if (breadcrumbs.length > 1) {
      setBreadcrumbs(breadcrumbs.slice(0, -1));
    }
  };

  const selectProject = (project: CloudFile) => {
    if (route.params?.onProjectSelect) {
      route.params.onProjectSelect(project);
      navigation.goBack();
    } else {
      navigation.navigate('Home', { selectedProject: project });
    }
  };

  const handleSignOut = async () => {
    try {
      await cloudService.signOut();
      navigation.goBack();
    } catch (error) {
      Alert.alert('Error', `Failed to sign out: ${error}`);
    }
  };

  const handleCreateProject = () => {
    setShowCreateDialog(true);
  };

  const confirmCreateProject = async () => {
    if (!newProjectName.trim()) {
      return;
    }

    setShowCreateDialog(false);
    setIsLoading(true);

    try {
      const projectName = newProjectName.endsWith('.scriv')
        ? newProjectName
        : `${newProjectName}.scriv`;
      const parentFolderId = breadcrumbs[breadcrumbs.length - 1]?.id;

      const projectFolder = await cloudService.createFolder(projectName, parentFolderId);

      setIsLoading(false);
      setNewProjectName('');

      if (projectFolder) {
        selectProject(projectFolder);
      }
    } catch (error) {
      setIsLoading(false);
      setNewProjectName('');
      Alert.alert('Error', `Failed to create project: ${error}`);
    }
  };

  const formatSize = (bytes?: number): string => {
    if (!bytes) return '';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const renderFileItem = ({ item }: { item: CloudFile }) => {
    const isScrivener = item.isScrivenerProject;
    const iconName = item.isDirectory ? 'folder' : 'insert-drive-file';
    const iconColor = item.isDirectory
      ? '#2196F3'
      : isScrivener
      ? '#4CAF50'
      : '#757575';

    return (
      <TouchableOpacity
        style={styles.fileItem}
        onPress={() => {
          if (isScrivener) {
            selectProject(item);
          } else if (item.isDirectory) {
            navigateToFolder(item);
          }
        }}
      >
        <Icon name={iconName} size={32} color={iconColor} />
        <View style={styles.fileInfo}>
          <Text style={styles.fileName}>{item.name}</Text>
          {!item.isDirectory && <Text style={styles.fileSize}>{formatSize(item.size)}</Text>}
        </View>
        {isScrivener && <Icon name="check-circle" size={24} color="#4CAF50" />}
      </TouchableOpacity>
    );
  };

  const renderBreadcrumb = (folder: CloudFile | null, index: number) => {
    const isLast = index === breadcrumbs.length - 1;
    return (
      <View key={index} style={styles.breadcrumbItem}>
        <Text
          style={[
            styles.breadcrumbText,
            isLast && styles.breadcrumbTextActive,
          ]}
        >
          {folder?.name || 'Root'}
        </Text>
        {!isLast && (
          <Icon name="chevron-right" size={16} color="#757575" style={styles.breadcrumbChevron} />
        )}
      </View>
    );
  };

  return (
    <View style={styles.container}>
      {/* Breadcrumb Navigation */}
      {breadcrumbs.length > 1 && (
        <View style={styles.breadcrumbContainer}>
          <TouchableOpacity onPress={navigateBack} style={styles.backButton}>
            <Icon name="arrow-back" size={24} color="#000" />
          </TouchableOpacity>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            style={styles.breadcrumbScroll}
          >
            {breadcrumbs.map(renderBreadcrumb)}
          </ScrollView>
        </View>
      )}

      {/* File List */}
      {isLoading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#673AB7" />
        </View>
      ) : currentFiles.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>No files found</Text>
        </View>
      ) : (
        <FlatList
          data={currentFiles}
          renderItem={renderFileItem}
          keyExtractor={(item) => item.id}
          style={styles.fileList}
        />
      )}

      {/* Create Project FAB */}
      {breadcrumbs.length === 1 && (
        <TouchableOpacity
          style={styles.fab}
          onPress={handleCreateProject}
        >
          <Icon name="add" size={24} color="#FFFFFF" />
          <Text style={styles.fabText}>New Project</Text>
        </TouchableOpacity>
      )}

      {/* Create Project Dialog */}
      <Modal
        visible={showCreateDialog}
        transparent
        animationType="fade"
        onRequestClose={() => setShowCreateDialog(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.dialogContent}>
            <Text style={styles.dialogTitle}>Create Scrivener Project</Text>
            <TextInput
              style={styles.dialogInput}
              placeholder="Project Name"
              placeholderTextColor="#999"
              value={newProjectName}
              onChangeText={setNewProjectName}
              autoFocus
            />
            <View style={styles.dialogButtons}>
              <TouchableOpacity
                style={styles.dialogButton}
                onPress={() => {
                  setShowCreateDialog(false);
                  setNewProjectName('');
                }}
              >
                <Text style={styles.dialogButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.dialogButton, styles.dialogButtonPrimary]}
                onPress={confirmCreateProject}
              >
                <Text style={[styles.dialogButtonText, styles.dialogButtonTextPrimary]}>
                  Create
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
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
  breadcrumbContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F5F5F5',
    padding: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#E0E0E0',
  },
  backButton: {
    padding: 8,
  },
  breadcrumbScroll: {
    flex: 1,
  },
  breadcrumbItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  breadcrumbText: {
    fontSize: 14,
    color: '#757575',
  },
  breadcrumbTextActive: {
    fontWeight: 'bold',
    color: '#000',
  },
  breadcrumbChevron: {
    marginHorizontal: 8,
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
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
  fileList: {
    flex: 1,
  },
  fileItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
  },
  fileInfo: {
    flex: 1,
    marginLeft: 16,
  },
  fileName: {
    fontSize: 16,
    color: '#000',
  },
  fileSize: {
    fontSize: 14,
    color: '#757575',
    marginTop: 4,
  },
  fab: {
    position: 'absolute',
    right: 16,
    bottom: 16,
    backgroundColor: '#673AB7',
    borderRadius: 28,
    paddingHorizontal: 20,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    elevation: 6,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
  },
  fabText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  dialogContent: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 24,
    width: '100%',
    maxWidth: 400,
  },
  dialogTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  dialogInput: {
    borderWidth: 1,
    borderColor: '#E0E0E0',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    marginBottom: 24,
  },
  dialogButtons: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  dialogButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    marginLeft: 8,
  },
  dialogButtonPrimary: {
    backgroundColor: '#673AB7',
    borderRadius: 8,
  },
  dialogButtonText: {
    fontSize: 16,
    color: '#673AB7',
    fontWeight: '600',
  },
  dialogButtonTextPrimary: {
    color: '#FFFFFF',
  },
});
