#!/bin/sh
set -eu

#分析机器磁盘的用量

# 使用第一个参数作为目录，如果未提供则默认为根目录
dir=${1:-/}

# 确认目录存在
if [ ! -d "$dir" ]; then
    echo "目录不存在: $dir"
    exit 1
fi

# 使用 find 查找文件，排除特定目录
# 注意逻辑运算符的顺序：如果路径匹配排除目录，则跳过，否则查找文件
find "$dir" \( -path "/proc" -o -path "/sys" -o -path "/boot" -o -path "/run" -o -path "/dev" \) -prune -o -type f -exec du -b -- {} + | awk -vOFS='\t' '
BEGIN {
    # 定义单位及其对应的基数
    split("B KB MB GB TB PB", u)
    base = 1024
}

{
    size = $1
    total += size
    count++

    # 根据10倍递增的范围进行分类
    if (size < 10) {
        hist["0-10B"]++
    }
    else if (size < 100) {
        hist["10-100B"]++
    }
    else if (size < 1000) {
        hist["100B-1KB"]++
    }
    else if (size < 10000) {
        hist["1KB-10KB"]++
    }
    else if (size < 100000) {
        hist["10KB-100KB"]++
    }
    else if (size < 1000000) {
        hist["100KB-1MB"]++
    }
    else if (size < 10000000) {
        hist["1MB-10MB"]++
    }
    else if (size < 100000000) {
        hist["10MB-100MB"]++
    }
    else if (size < 1000000000) {
        hist["100MB-1GB"]++
    }
    else if (size < 10000000000) {
        hist["1GB-10GB"]++
    }
    else if (size < 100000000000) {
        hist["10GB-100GB"]++
    }
    else {
        hist[">100GB"]++
    }
}

END {
    if (count == 0) {
        print "No files found."
        exit 0
    }

    print "Range", "Count"
    # 按照定义的顺序打印范围
    ranges = "0-10B 10-100B 100B-1KB 1KB-10KB 10KB-100KB 100KB-1MB 1MB-10MB 10MB-100MB 100MB-1GB 1GB-10GB 10GB-100GB >100GB"
    n = split(ranges, arr, " ")
    for (i = 1; i <= n; i++) {
        range = arr[i]
        if (range in hist)
            print range, hist[range]
        else
            print range, 0
    }

    # 计算总大小并转换单位
    unit = "B"
    total_size = total
    if (total_size >= base) {
        total_size /= base
        unit = "KB"
    }
    if (total_size >= base) {
        total_size /= base
        unit = "MB"
    }
    if (total_size >= base) {
        total_size /= base
        unit = "GB"
    }
    if (total_size >= base) {
        total_size /= base
        unit = "TB"
    }
    if (total_size >= base) {
        total_size /= base
        unit = "PB"
    }
    printf "\nTotal: %.1f%s in %d files\n", total_size, unit, count
}'