# -------------------------------------------
# Portal Class
# -------------------------------------------require 'test/unit'

require 'matrix'

class Portal
  attr_reader :longitude,:latitude,:portalname,:pid   # 設定値
  @@pid = 0       # ポータル番号（クラス変数）

  def initialize(longitude=0.0,latitude=0.0,portalname="")
    @longitude = longitude.to_f
    @latitude = latitude.to_f
    @portalname = portalname
    @pid = getNumber()
  end

  # 読み込んだ順にポータル番号を割り当てる
  def getNumber 
     @@pid +=  1
  end
  
  #　設定値をVectorで取り出す(外積を使うので３次元ベクトル)
  def vector 
    Vector[@longitude ,@latitude,0]
  end

  # 設定値を文字列で出力します（No,ポータル名,経度,緯度）
  def print 
    return "[#{@pid}]\t#{@latitude},#{@longitude},#{@portalname}"
  end
end
