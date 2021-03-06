class Gdal2Grass7 < Formula
  desc "GDAL/OGR 2.x plugin for GRASS 7"
  homepage "http://www.gdal.org"
  url "http://download.osgeo.org/gdal/2.3.2/gdal-grass-2.3.2.tar.gz"
  sha256 "26c2dcff6e668c34455becb379d126715eb70d7f51962c48ba71ea3bdc5f30fa"

  bottle do
    root_url "https://dl.bintray.com/homebrew-osgeo/osgeo-bottles"
    rebuild 1
    sha256 "a386bae7bf615c712d4d236fd518f021cebe8da80e1d00a9ed5dd0121dbbaaa1" => :mojave
    sha256 "a386bae7bf615c712d4d236fd518f021cebe8da80e1d00a9ed5dd0121dbbaaa1" => :high_sierra
    sha256 "a386bae7bf615c712d4d236fd518f021cebe8da80e1d00a9ed5dd0121dbbaaa1" => :sierra
  end

  depends_on "gdal2"
  depends_on "grass7"

  def gdal_majmin_ver
    gdal_ver_list = Formula["gdal2"].version.to_s.split(".")
    "#{gdal_ver_list[0]}.#{gdal_ver_list[1]}"
  end

  def gdal_plugins_subdirectory
    "gdalplugins/#{gdal_majmin_ver}"
  end

  def install
    ENV.cxx11
    gdal = Formula["gdal2"]
    gdal_plugins = lib/gdal_plugins_subdirectory
    gdal_plugins.mkpath

    grass = Formula["grass7"]

    # due to DYLD_LIBRARY_PATH no longer being setable, strictly define extension
    inreplace "Makefile.in", ".so", ".dylib"

    system "./configure", "--prefix=#{prefix}",
                          "--disable-debug",
                          "--disable-dependency-tracking",
                          "--with-gdal=#{gdal.opt_bin}/gdal-config",
                          "--with-grass=#{grass.prefix}/grass-#{grass.version}",
                          "--with-autoload=#{gdal_plugins}"

    # inreplace "Makefile", "mkdir", "mkdir -p"

    system "make", "install"
  end

  def caveats; <<~EOS
      This formula provides a plugin that allows GDAL or OGR to access geospatial
      data stored in its format. In order to use the shared plugin, you may need
      to set the following enviroment variable:

        export GDAL_DRIVER_PATH=#{HOMEBREW_PREFIX}/lib/gdalplugins
    EOS
  end

  test do
    ENV["GDAL_DRIVER_PATH"] = "#{HOMEBREW_PREFIX}/lib/gdalplugins"
    gdal_opt_bin = Formula["gdal2"].opt_bin
    out = shell_output("#{gdal_opt_bin}/gdalinfo --formats")
    assert_match "GRASS -raster- (ro)", out
    out = shell_output("#{gdal_opt_bin}/ogrinfo --formats")
    assert_match "OGR_GRASS -vector- (ro)", out
  end
end
