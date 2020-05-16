
#
# ポータル３点と候補ポータル群
#
require './Portal'

class Finder
  attr_accessor :layer,:child_layer

  # 内側のポータル数   1   2   3    4    5    6    7
  INSIDE_COUNT = [0,  0,  1,  4,  13,  40, 121, 364]

  def initialize( layer )
    @layer = layer.to_i
    @child_layer = layer - 1
  end

  def search(cf, portals)

    # ３頂点のポータルを取り出す
    a = cf.a; b = cf.b; c = cf.c

   # puts "#{" "*(7 - @layer)}[#{layer}] #{a.portalname}, #{b.portalname}, #{c.portalname}"

    # 最下層まで検索した
    return true if layer == 1
    
    # portalsの中でcfに含まれるポータルのリストを取得する
    tmp_portals = cf.inside(portals)

    # ３つの下位の完全多重が出来るか
    tmp_portals.each_pair do |key,px|
      # 探索中のポータルを設定
      cf.center_portal = px
      cf.layer = layer
      # 分割されるCFを３つ作成する
      cf_a = Cf.new(px, b,  c );  portals_a = cf_a.inside(tmp_portals)
      cf_b = Cf.new(a,  px, c );  portals_b = cf_b.inside(tmp_portals)
      cf_c = Cf.new(a,  b,  px);  portals_c = cf_c.inside(tmp_portals)

      # このレイヤーで必要なポータル数を満たしているか？
      if portals_a.count >= INSIDE_COUNT[layer - 1 ] and 
         portals_b.count >= INSIDE_COUNT[layer - 1 ] and
         portals_c.count >= INSIDE_COUNT[layer - 1 ] 
          ;
      else
          next # 次のポータルの処理に移ります
      end

      # ひとつ下階層の検索処理を作成する
      f = Finder.new( layer - 1 )

      # 下位の３つのCFがすべて成立しているか
      if f.search(cf_a,portals_a) and 
         f.search(cf_b,portals_b) and 
         f.search(cf_c,portals_c)
        
        # 親CFに下位のCFを登録,自分のCFに親CFを登録
        cf.set_child(cf_a); cf_a.set_parent(cf);
        cf.set_child(cf_b); cf_b.set_parent(cf);
        cf.set_child(cf_c); cf_c.set_parent(cf);


        return true   # 下位のポータルが成立した
      else
        return false # 下位のCFが成立しなかった
      end

    end
    return false #　内部の全ポータルを検索して見つからなかった
  end

end

