const fs = require('fs');
const path = require('path');

const CDN_PREFIX = 'https://cdn.jsdelivr.net/gh/AmazingAng/WTF-Solidity';

// 递归查找所有的 readme.md 文件
function findReadmeFiles(dir) {
    let results = [];
    const files = fs.readdirSync(dir);
    
    for (const file of files) {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);
        
        if (stat.isDirectory() && !file.startsWith('.')) {
            // 递归搜索子目录
            results = results.concat(findReadmeFiles(filePath));
        } else if (file.toLowerCase() === 'readme.md') {
            results.push(filePath);
        }
    }
    
    return results;
}

// 处理图片链接
function processImageLinks(content, dirName) {
    const imageRegex = /!\[(.*?)\]\((\.\/[^)]+)\)/g;
    return content.replace(imageRegex, (match, altText, imagePath) => {
        // 移除开头的 ./
        const cleanImagePath = imagePath.replace(/^\.\//, '');
        // 构建新的 CDN URL
        const cdnUrl = `${CDN_PREFIX}/${dirName}/${cleanImagePath}`;
        return `![${altText}](${cdnUrl})`;
    });
}

async function main() {
    try {
        const readmeFiles = findReadmeFiles('.');
        console.log(`找到 ${readmeFiles.length} 个 readme.md 文件`);
        for (const readmePath of readmeFiles) {
            const content = fs.readFileSync(readmePath, 'utf-8');
            const dirName = path.dirname(readmePath);
            
            // 处理内容
            const processedContent = processImageLinks(content, dirName);
            
            // 只有当内容有变化时才创建新文件
            if (content !== processedContent) {
                // 生成新文件路径
                const mirrorPath = path.join(dirName, 'readme_mirror.md');
                fs.writeFileSync(mirrorPath, processedContent, 'utf-8');
                console.log(`已生成镜像文件: ${mirrorPath}`);
            }
        }
        console.log('处理完成！');
    } catch (error) {
        console.error('处理过程中出错：', error);
    }
}

main();
