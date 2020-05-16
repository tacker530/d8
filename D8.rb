# ---------------------------------------------------------
#
#    D8.rb
#
#    [Usage] ruby D8.rb データファイル名 (-7,-6,-5,-4,-3)"
#  
# ---------------------------------------------------------
#    Create 2020/05/10   tacker530 rewrite D7.rb -> D8.rb   
#    Update 2020/05/16   tacker530 iso compatible support   
# ---------------------------------------------------------

require "csv"
require 'optparse'

require './Portal'
require './CF'
require './Finder'

opt = OptionParser.new

layer = 4   # デフォルト(全４重）
opt.on('-7'){|v|layer = 7}
opt.on('-6'){|v|layer = 6}
opt.on('-5'){|v|layer = 5}
opt.on('-4'){|v|layer = 4}
opt.on('-3'){|v|layer = 3}
argv = opt.parse(ARGV)

if argv[0] then
  filename = argv[0]
else
  puts "[Usage] ruby D8.rb データファイル名 (-7,-6,-5,-4,-3)"
  return
end

# data hash setup
portals = {}
CSV.foreach(filename) do |row|
  px = Portal.new(row[0],row[1],row[2] )
  portals[px.pid] = px
end

# portals fillter (no1,2,3)
a = portals[1]
b = portals[2]
c = portals[3]

# 確認するCF(△abc)
cf = Cf.new(a,b,c,"root") # 最上位のフラグ設定

# ポータル群の中から下位の完全多重を見つける
f = Finder.new( layer )

if f.search(cf,portals)
  # 階層構造のツリー表示
  puts cf.tree
  # 全多重の対象ポータル(深さ優先検索)
  puts cf.portallist
  # isoさんと互換（幅優先検索）
  puts cf.isolist
  # IITC Drawtoolsのテキスト
  puts cf.linklist
else
  puts "見つかりませんでした"
end