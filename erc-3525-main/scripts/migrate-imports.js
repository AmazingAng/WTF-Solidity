#!/usr/bin/env node

const { promises: fs } = require('fs');
const path = require('path');

const pathUpdates = [
  'utils/ContextUpgradeable.sol',
  'utils/introspection/ERC165Upgradeable.sol',
  'utils/StringsUpgradeable.sol',
  'utils/AddressUpgradeable.sol',
  'utils/CountersUpgradeable.sol',
  'utils/introspection/IERC165Upgradeable.sol',
  'token/ERC721/IERC721ReceiverUpgradeable.sol',
  'utils/Base64Upgradeable.sol'
]

async function main (paths = [ 'contracts' ]) {
  const files = await listFilesRecursively(paths, /\Upgradeable.sol$/);

  const updatedFiles = [];
  for (const file of files) {
      console.log(`Update ${file}`);
    if (await updateFile(file, updateImportPaths)) {
      updatedFiles.push(file);
    }
  }

  if (updatedFiles.length > 0) {
    console.log(`${updatedFiles.length} file(s) were updated`);
    for (const c of updatedFiles) {
      console.log('-', c);
    }
  } else {
    console.log('No files were updated');
  }
}

async function listFilesRecursively (paths, filter) {
  const queue = paths;
  const files = [];

  while (queue.length > 0) {
    const top = queue.shift();
    const stat = await fs.stat(top);
    if (stat.isFile()) {
      if (top.match(filter)) {
        files.push(top);
      }
    } else if (stat.isDirectory()) {
      for (const name of await fs.readdir(top)) {
        queue.push(path.join(top, name));
      }
    }
  }

  return files;
}

async function updateFile (file, update) {
  const content = await fs.readFile(file, 'utf8');
  const updatedContent = update(content);
  if (updatedContent !== content) {
    await fs.writeFile(file, updatedContent);
    return true;
  } else {
    return false;
  }
}

function updateImportPaths (source) {
  for (const filePath of pathUpdates) {
    source = source.replace(
      path.join('@openzeppelin/contracts/', filePath),
      path.join('@openzeppelin/contracts-upgradeable/', filePath),
    );
    source = source.replace(
      '../Initializable.sol',
      '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol');
    source = source.replace(
      './Initializable.sol',
      '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol');
  }
  return source;
}

function getUpgradeablePath (file) {
  const { dir, name, ext } = path.parse(file);
  const upgradeableName = name + 'Upgradeable';
  return path.format({ dir, ext, name: upgradeableName });
}

module.exports = {
  pathUpdates,
  updateImportPaths,
  getUpgradeablePath,
};

if (require.main === module) {
  const args = process.argv.length > 2 ? process.argv.slice(2) : undefined;
  main(args).catch(e => {
    console.error(e);
    process.exit(1);
  });
}
