import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'common.dart';
import 'options/theme/_filelist_theme.dart';

/// A single row displaying a folder or file, the corresponding icon and the trailing
/// selection button for the file (configured in the `fileTileSelectMode` parameter).
///
/// Used in conjunction with the `FilesystemList` widget.
class FilesystemListTile extends StatelessWidget {
  /// The type of view (folder and files, folder only or files only), by default `FilesystemType.all`.
  final FilesystemType fsType;

  /// The entity of the file system that should be displayed by the widget.
  final FileSystemEntity item;

  /// The color of the folder icon in the list.
  final Color? folderIconColor;

  /// Called when the user has touched a subfolder list item.
  final ValueChanged<Directory> onChange;

  /// Called when a file system item is selected.
  final ValueSelected onSelect;

  /// Specifies how to files can be selected (either tapping on the whole tile or only on trailing button).
  final FileTileSelectMode fileTileSelectMode;

  /// Specifies a list theme in which colors, fonts, icons, etc. can be customized.
  final FilesystemPickerFileListThemeData? theme;

  /// Specifies the extension comparison mode to determine the icon specified for the file types in the theme,
  /// case-sensitive or case-insensitive, by default it is insensitive.
  final bool caseSensitiveFileExtensionComparison;

  /// Creates a file system entity list tile.
  const FilesystemListTile({
    Key? key,
    this.fsType = FilesystemType.all,
    required this.item,
    this.folderIconColor,
    required this.onChange,
    required this.onSelect,
    required this.fileTileSelectMode,
    this.theme,
    this.caseSensitiveFileExtensionComparison = false,
  }) : super(key: key);

  Widget _leading(BuildContext context, FilesystemPickerFileListThemeData theme,
      bool isFile) {
    if (item is Directory) {
      return Icon(
        theme.getFolderIcon(context),
        color: theme.getFolderIconColor(context, folderIconColor),
        size: theme.getIconSize(context),
      );
    } else {
      return _fileIcon(context, theme, item.path, isFile);
    }
  }

  /// Set the icon for a file
  Icon _fileIcon(BuildContext context, FilesystemPickerFileListThemeData theme,
      String filename, bool isFile,
      [Color? color]) {
    final entryExtension = filename.split(".").last;
    IconData icon = theme.getFileIcon(
        context, entryExtension, caseSensitiveFileExtensionComparison);

    return Icon(
      icon,
      color: theme.getFileIconColor(context, color),
      size: theme.getIconSize(context),
    );
  }

  Widget? _trailing(BuildContext context,
      FilesystemPickerFileListThemeData theme, bool isFile) {
    final isCheckable = ((fsType == FilesystemType.all) ||
        ((fsType == FilesystemType.file) &&
            (item is File) &&
            (fileTileSelectMode != FileTileSelectMode.wholeTile)));

    if (isCheckable) {
      final iconTheme = theme.getCheckIconTheme(context);
      return InkResponse(
        child: Icon(
          theme.getCheckIcon(context),
          color: iconTheme.color,
          size: iconTheme.size,
        ),
        onTap: () => onSelect(item.absolute.path),
      );
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dirContents,
      builder: (BuildContext context,
          AsyncSnapshot<List<FileSystemEntity>> snapshot) {
        final effectiveTheme =
            widget.theme ?? FilesystemPickerFileListThemeData();

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text('Error loading file list: ${snapshot.error}',
                    textScaleFactor:
                        effectiveTheme.getTextScaleFactor(context, true)),
              ),
            );
          } else if (snapshot.hasData) {
            bool isAllImage = true;
            snapshot.data?.forEach((item) {
              final isImage = item.absolute.path.endsWith(".png") ||
                  item.absolute.path.endsWith(".jpg");
              isAllImage &= isImage;
            });
            if (isAllImage) {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, //每行三列
                  childAspectRatio: 0.8, //显示区域宽高相等
                ),
                itemCount: snapshot.data!.length +
                    (widget.showGoUp ? (widget.isRoot ? 0 : 1) : 0),
                itemBuilder: (BuildContext context, int index) {
                  if (widget.showGoUp && !widget.isRoot && index == 0) {
                    return _upNavigation(context, effectiveTheme);
                  }

                  final item = snapshot.data![
                      index - (widget.showGoUp ? (widget.isRoot ? 0 : 1) : 0)];
                  return FilesystemListTile(
                    fsType: widget.fsType,
                    item: item,
                    folderIconColor: widget.folderIconColor,
                    onChange: widget.onChange,
                    onSelect: widget.onSelect,
                    fileTileSelectMode: widget.fileTileSelectMode,
                    theme: effectiveTheme,
                    caseSensitiveFileExtensionComparison:
                        widget.caseSensitiveFileExtensionComparison,
                  );
                },
              );
            } else {
              return ListView.builder(
                controller: widget.scrollController,
                shrinkWrap: true,
                itemCount: snapshot.data!.length +
                    (widget.showGoUp ? (widget.isRoot ? 0 : 1) : 0),
                itemBuilder: (BuildContext context, int index) {
                  if (widget.showGoUp && !widget.isRoot && index == 0) {
                    return _upNavigation(context, effectiveTheme);
                  }

                  final item = snapshot.data![
                      index - (widget.showGoUp ? (widget.isRoot ? 0 : 1) : 0)];
                  return FilesystemListTile(
                    fsType: widget.fsType,
                    item: item,
                    folderIconColor: widget.folderIconColor,
                    onChange: widget.onChange,
                    onSelect: widget.onSelect,
                    fileTileSelectMode: widget.fileTileSelectMode,
                    theme: effectiveTheme,
                    caseSensitiveFileExtensionComparison:
                        widget.caseSensitiveFileExtensionComparison,
                  );
                },
              );
            }
          } else {
            return const SizedBox();
          }
        } else {
          return FilesystemProgressIndicator(theme: effectiveTheme);
        }
      },
    );
  }
}
