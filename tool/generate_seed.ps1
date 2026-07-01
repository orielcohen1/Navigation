# Converts app/assets/data/mall_data.json into supabase/seed.sql
# Usage: powershell -File tool/generate_seed.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root 'app\assets\data\mall_data.json'
$outPath  = Join-Path $root 'supabase\seed.sql'

function Sql-Str($s) {
  if ($null -eq $s) { return 'null' }
  return "'" + ($s -replace "'", "''") + "'"
}

$data = Get-Content $jsonPath -Raw | ConvertFrom-Json

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("-- Generated from app/assets/data/mall_data.json by tool/generate_seed.ps1")
$lines.Add("-- Run this in the Supabase SQL Editor AFTER schema.sql")
$lines.Add("")

$vid = Sql-Str $data.id
$lines.Add("insert into venues (id, name, map_width, map_height, meters_per_unit) values")
$lines.Add("  ($vid, $(Sql-Str $data.name), $($data.mapWidth), $($data.mapHeight), $($data.metersPerUnit));")
$lines.Add("")

foreach ($floor in $data.floors) {
  $fid = Sql-Str $floor.id
  $lines.Add("insert into floors (venue_id, id, name) values")
  $lines.Add("  ($vid, $fid, $(Sql-Str $floor.name));")
}
$lines.Add("")

$nodeRows = New-Object System.Collections.Generic.List[string]
foreach ($floor in $data.floors) {
  $fid = Sql-Str $floor.id
  foreach ($n in $floor.nodes) {
    $nodeRows.Add("  ($vid, $fid, $(Sql-Str $n.id), $($n.x), $($n.y), $(Sql-Str $n.label))")
  }
}
if ($nodeRows.Count -gt 0) {
  $lines.Add("insert into nodes (venue_id, floor_id, id, x, y, label) values")
  $lines.Add(($nodeRows -join ",`n") + ";")
}
$lines.Add("")

$edgeRows = New-Object System.Collections.Generic.List[string]
foreach ($floor in $data.floors) {
  $fid = Sql-Str $floor.id
  foreach ($e in $floor.edges) {
    $w = if ($e.weight) { $e.weight } else { 1.0 }
    $edgeRows.Add("  ($vid, $fid, $(Sql-Str $e.from), $(Sql-Str $e.to), $w)")
  }
}
if ($edgeRows.Count -gt 0) {
  $lines.Add("insert into edges (venue_id, floor_id, from_node, to_node, weight) values")
  $lines.Add(($edgeRows -join ",`n") + ";")
}
$lines.Add("")

$qrRows = New-Object System.Collections.Generic.List[string]
foreach ($floor in $data.floors) {
  $fid = Sql-Str $floor.id
  foreach ($q in $floor.qrCodes) {
    $qrRows.Add("  ($vid, $fid, $(Sql-Str $q.id), $(Sql-Str $q.nodeId), $(Sql-Str $q.label))")
  }
}
if ($qrRows.Count -gt 0) {
  $lines.Add("insert into qr_codes (venue_id, floor_id, id, node_id, label) values")
  $lines.Add(($qrRows -join ",`n") + ";")
}
$lines.Add("")

$ifeRows = New-Object System.Collections.Generic.List[string]
foreach ($ife in $data.interFloorEdges) {
  $ifeRows.Add("  ($vid, $(Sql-Str $ife.fromNodeId), $(Sql-Str $ife.toNodeId), $(Sql-Str $ife.type))")
}
if ($ifeRows.Count -gt 0) {
  $lines.Add("insert into inter_floor_edges (venue_id, from_node, to_node, type) values")
  $lines.Add(($ifeRows -join ",`n") + ";")
}
$lines.Add("")

$poiRows = New-Object System.Collections.Generic.List[string]
foreach ($p in $data.pois) {
  $poiRows.Add("  ($vid, $(Sql-Str $p.id), $(Sql-Str $p.name), $(Sql-Str $p.category), $(Sql-Str $p.floorId), $(Sql-Str $p.nodeId), $(Sql-Str $p.icon))")
}
if ($poiRows.Count -gt 0) {
  $lines.Add("insert into pois (venue_id, id, name, category, floor_id, node_id, icon) values")
  $lines.Add(($poiRows -join ",`n") + ";")
}

Set-Content -Path $outPath -Value ($lines -join "`n") -Encoding utf8
Write-Host "Wrote $outPath"
