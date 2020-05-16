require './Portal'
require 'matrix'

# -------------------------------------------
# Control field
#  △ABCに含まれるポータルを抽出する
# -------------------------------------------
class Cf
  attr_accessor :a, :b, :c       # 対象とする三角形の頂点(Portal)
  attr_accessor :va, :vb, :vc    # 対象とする三角形の頂点(Vector)
  attr_accessor :ab,:bc,:ca　    # 各辺のベクトル a->b->c->a ...(Vector)
  attr_reader   :ic              # △abcの内心ic(Vector)
  attr_reader   :inside_portals  # △abcの内側のポータルすべて
  attr_accessor :center_portal   # 中央の分割中心となるポータル
  attr_accessor :layer           # 何層目のCFかを示す
  attr_accessor :root            # 最上位のCFを示す（true:最上位、false:それ以外）

  # CFの頂点を設定する a,b,cはPodtalクラス
  def initialize(a, b, c, root = nil)
    @a = a; @b = b; @c = c
    @va = a.vector; @vb = b.vector;  @vc = c.vector
    # 三角形の各辺のベクトル（a->b->c->a）
    @ab = @vb - @va
    @bc = @vc - @vb
    @ca = @va - @vc
    # 内心
    @ic = inner_center
    # 最上位
    @root = root
    # 下位のCF
    @child = Array.new
    @layer = nil
    @center_portal = nil
  end

  # 3角形の内心を調べる(デフォルトで⊿abc)
  # http://examist.jp/mathematics/planar-vector/naisin-vector/
  def inner_center( a = @va, b = @vb ,c=@vc )
    @ic ||= (a * a.r + b * b.r + c * c.r )/(a.r + b.r + c.r) 
  end


  # 三角形と点の当たり判定(△ABCの中か外か？)
  # 戻り値    True:三角形の内側に点がある    
  #          False:三角形の外側に点がある
  def include?(px)
    #外積の算出
    z1 = @ab.cross_product( px.vector - @va )
    z2 = @bc.cross_product( px.vector - @vb )
    z3 = @ca.cross_product( px.vector - @vc )
    # 三角形の内側にある 外積が全て同じ方向（全部＋または全部ー）
    if     (z1[2] > 0 and  z2[2] > 0 and  z3[2] > 0 ) \
       ||  (z1[2] < 0 and  z2[2] < 0 and  z3[2] < 0 ) then
      return true  # 内側にある
    else
      return false # 内側にない
    end
  end

  # CFの内心との距離を測る
  def distance(px, base = @ic)
     (base - px.vector).r.abs
  end

  # 対象ポータル一覧から△abcに含まれるポータルを抽出する
  def inside(portals)
    selected_portals = {} 
    portals.each_pair do |k,px|
      if self.include?(px)              # △abcに含まれるか
        selected_portals[px.pid] = px   # 選択されたポータルをハッシュに登録
      end
    end
    # puts "△abc = #{selected_portals.count}: [#{@pa.pid}]#{@pa.portalname},[#{@pb.pid}]#{@pb.portalname},[#{@pc.pid}]#{@pc.portalname}"
    # 抽出されたポータルを内心との距離の近い順にソートする
    inside_portals = selected_portals.sort_by {|key,px| self.distance(px) }.to_h
  end

  #
  # CFに組み込み
  #
  def search(portals,layer)

    # ３頂点のポータルを取り出す
    # a = cf.a; b = cf.b; c = cf.c

    puts "#{" "*(7 - @layer)}[#{layer}] #{@a.portalname}, #{@b.portalname}, #{@c.portalname}"

    # 最下層まで検索した
    return true if layer == 1
    
    # portalsの中でcfに含まれるポータルのリストを取得する
    tmp_portals = cf.inside(portals)

    # ３つの下位の完全多重が出来るか
    tmp_portals.each_pair do |key,px|
  
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

        # 候補になるCFを準備
        child = Result.new(cf,px)
        child.set_parent(result) # 子供のCFの親にCFを設定
        result.set_child(child) # 親のCFに子供を設定
        return true   # 下位のポータルが成立した

      else
        return false # 下位のCFが成立しなかった
      end

    end
    return false #　内部の全ポータルを検索して見つからなかった
  end

  ###############################
  #  CFの親子関係
  ###############################
  # 自分の親CF
  def set_parent(parent)
    @parent = parent
  end
  # 自分の子CF
  def set_child(child)
   @child.push(child)
  end
  # 自分の子CF
  def child
     if @child.length > 0 then
      return @child
    end 
  end
  # 自分の子CF
  def remove_child
    if @child.length > 0 then
      # 配下のChildをすべて消す
      @child = []  
      return true
    end
  end

  #下位のCFの数
  def length
    return @child.length
  end

  #debug print
  def portalinfo(px)
    print  "#{sprintf('%.6f',px.longitude)},#{sprintf('%.6f',px.latitude)},\"[#{px.pid}] #{px.portalname}\"\n"
  end

  def portallist
    # 中心が未設定ならば出力しない
    return if center_portal == nil

    # Portal information
    # 最上位の外周ポータルの情報
    if root then
      print "\n--- portal list ---\n"
      print "\nlongitude,\tlatitude,\tportalname\n"
      portalinfo(a); portalinfo(b); portalinfo(c)
    end
    # 通常の下位のCFの情報
    if center_portal then
      portalinfo(center_portal)          
    end
    
    # 下位のポータルを出力
    @child.each_with_index do | portal,i|
      portal.portallist
    end
    " "

  end


  def leaf(px,layer)
    print  "#{"  "*(7 - layer)} [#{px.pid}] #{px.portalname}\t([#{a.pid}] #{a.portalname},[#{b.pid}] #{b.portalname},[#{c.pid}] #{c.portalname}) \n"
  end

  def tree
    # 中心が未設定ならば出力しない
    return if center_portal == nil

    # Portal information
    # 最上位の外周ポータルの情報
    if root then
      print "\n--- tree list ---\n\n"

      leaf(a, @layer + 1 )
      leaf(b, @layer + 1 )
      leaf(c, @layer + 1 )
    end
    # 通常の下位のCFの情報
    if center_portal then
      leaf(center_portal,@layer)  
    end
    
    # 下位のポータルを出力
    @child.each_with_index do | portal,i|
      portal.tree
    end
    " "
  end

  def linklist
    # 中心が未設定ならば出力しない
    return if center_portal == nil
    # 
    # ",{\"type\":\"polyline\",\"latLngs\":[{\"lat\":36.571202,\"lng\":136.629249},{\"lat\":36.585676,\"lng\":136.679618}],\"color\":\"dodgerblue\"}\n"
    linkBEGIN = "[\n"
    linkA = "{\"type\":\"polyline\",\"latLngs\":[{\"lat\":"
    linkB = ",\"lng\":"
    linkC = "},{\"lat\":"
    linkD = ",\"lng\":"
    linkE = "}],\"color\":\"dodgerblue\"}\n"
    linkEND ="]"

    # Link information
    if root then
      print "\n--- Drawtools list ---\n\n"
      print linkBEGIN
      # 最外周ならば△abcのリンクを描く
      print " " + linkA + "#{sprintf('%.6f',@a.latitude)}" + linkB + "#{sprintf('%.6f',@a.longitude)}" + linkC + "#{sprintf('%.6f',b.latitude)}" +  linkD +"#{sprintf('%.6f',b.longitude)}" + linkE
      print "," + linkA + "#{sprintf('%.6f',@b.latitude)}" + linkB + "#{sprintf('%.6f',@b.longitude)}" + linkC + "#{sprintf('%.6f',c.latitude)}" +  linkD +"#{sprintf('%.6f',c.longitude)}" + linkE
      print "," + linkA + "#{sprintf('%.6f',@c.latitude)}" + linkB + "#{sprintf('%.6f',@c.longitude)}" + linkC + "#{sprintf('%.6f',a.latitude)}" +  linkD +"#{sprintf('%.6f',a.longitude)}" + linkE
    end

    # 内側なら中心と△abcとのリンクを描く
    print "," + linkA + "#{sprintf('%.6f',center_portal.latitude)}" + linkB + "#{sprintf('%.6f',center_portal.longitude)}" + linkC + "#{sprintf('%.6f',a.latitude)}" +  linkD +"#{sprintf('%.6f',a.longitude)}" + linkE
    print "," + linkA + "#{sprintf('%.6f',center_portal.latitude)}" + linkB + "#{sprintf('%.6f',center_portal.longitude)}" + linkC + "#{sprintf('%.6f',b.latitude)}" +  linkD +"#{sprintf('%.6f',b.longitude)}" + linkE
    print "," + linkA + "#{sprintf('%.6f',center_portal.latitude)}" + linkB + "#{sprintf('%.6f',center_portal.longitude)}" + linkC + "#{sprintf('%.6f',c.latitude)}" +  linkD +"#{sprintf('%.6f',c.longitude)}" + linkE
  
    # 下位のリンクを出力
    @child.each_with_index do | portal,i|
      portal.linklist
    end
    print linkEND if root 
  end

  # ポータルリストを幅優先で検索したリスト
  # CFのcener_portalは多重の場合は存在するが、最下位の１重の場合はnilである。
  def isolist
    # ポータルの一覧
    patterns = []
    # キューを用意する。
    queue = [self]             #初期状態として自分自身を設定する。(CF)
    until queue.empty?         # キューが空になるまで

      cf = queue.shift         # キューから取り出してCFに設定
      if cf.center_portal      # 最下位のCFでなければ
        patterns << cf         # 出力用の配列に設定する
        cf.child.each do |child|  
          queue << child       # 下位の３つのCFをキューに設定する
        end
      end

    end

    # 出力対象を順番に表示する
    patterns.each do |cf|
      if cf.root then     # 最上位ポータル
        print "\n--- iso pattern list ---\n\n"
        portalinfo(cf.a)
        portalinfo(cf.b)
        portalinfo(cf.c)
      end

      portalinfo(cf.center_portal)  # 中央ポータル
    end
    " "
  end

end