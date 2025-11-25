parameter _dataSet.
for dat in _dataSet
{
    log "{0},{1}":Format(dat:name, dat:suffix) to outputPath.
}