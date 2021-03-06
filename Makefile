#
# Copyright (C) 2019 Xingwang Liao
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=v2ray-core
PKG_VERSION:=4.18.2
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/v2ray/v2ray-core/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=102dc6d7193ebd6c03f289e9ba107324d572adca7b150672709818d9a3edd115

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Xingwang Liao <kuoruan@gmail.com>

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=v2ray.com/core

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/v2ray-core/Default
  TITLE:=A platform for building proxies
  URL:=https://www.v2ray.com
endef

define Package/v2ray-core/Default/description
Project V is a set of network tools that help you to build your own computer network.
It secures your network connections and thus protects your privacy.
endef

define project-v/SubMenu
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Project V
endef

define v2ray-core/GoBinDefault
  $(call Package/v2ray-core/Default)
  $(call project-v/SubMenu)
  USERID:=v2ray=10800:v2ray=10800
  DEPENDS:=$(GO_ARCH_DEPENDS)
endef

define v2ray-core/templates
  define Package/$(1)
  $$(call v2ray-core/GoBinDefault)
    TITLE+= ($(1))
    DEPENDS:=+ca-certificates
  endef

  define Package/$(1)/description
  $$(call Package/v2ray-core/Default/description)

  This package contains the $(1).
  endef

  define Package/$(1)/install
	$$(INSTALL_DIR) $$(1)/usr/bin
	$$(INSTALL_BIN) $$(GO_PKG_BUILD_BIN_DIR)/$(1) $$(1)/usr/bin
  endef
endef

V2RAY_COMPONENTS:=v2ray v2ctl

$(foreach component,$(V2RAY_COMPONENTS), \
  $(eval $(call v2ray-core/templates,$(component))) \
)

define Package/v2ray-assets
  $(call Package/v2ray-core/Default)
  $(call project-v/SubMenu)
  TITLE+= (geoip & geosite)
endef

define Package/v2ray-assets/description
$(call Package/v2ray-core/Default/description)

  This package contains geoip.dat & geosite.dat.
endef

define Package/v2ray-assets/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/release/config/{geoip,geosite}.dat \
		$(1)/usr/bin
endef

define Package/v2ray-core
$(call v2ray-core/GoBinDefault)
  TITLE+= (full)
  PROVIDES:=$(V2RAY_COMPONENTS) v2ray-assets
  DEPENDS:=+ca-certificates
endef

define Package/v2ray-core/description
$(call Package/v2ray-core/Default/description)

  This package contains v2ray, v2ctl and v2ray-assets.
endef

define Package/v2ray-core/install
$(call Package/v2ray-assets/install,$(1))
	$(INSTALL_DIR) $(1)/usr/bin
	( \
		for component in $(V2RAY_COMPONENTS); do \
			$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/$$$$component $(1)/usr/bin ; \
		done ; \
	)
endef

define Package/golang-v2ray-core-dev
$(call Package/v2ray-core/Default)
$(call GoPackage/GoSubMenu)
  TITLE+= (source files)
  PKGARCH:=all
endef

define Package/golang-v2ray-core-dev/description
$(call Package/v2ray-core/Default/description)

This package provides the source files for v2ray-core.
endef

define Build/Prepare
	$(Build/Prepare/Default)
	( \
		sed -i \
			's/\(version[[:space:]]*=[[:space:]]*"\).*\("\)/\1$(PKG_VERSION)\2/' \
			$(PKG_BUILD_DIR)/core.go ; \
		build="OpenWrt - Release $(PKG_RELEASE)" ; \
		sed -i \
			"s/\(build[[:space:]]*=[[:space:]]*\"\).*\(\"\)/\1$$$$build\2/" \
			$(PKG_BUILD_DIR)/core.go ; \
	)
endef

define Build/Compile
	$(eval GO_PKG_BUILD_PKG:=v2ray.com/core/main)
	$(call GoPackage/Build/Compile,-ldflags "-s -w")
	mv -f $(GO_PKG_BUILD_BIN_DIR)/main $(GO_PKG_BUILD_BIN_DIR)/v2ray

	$(eval GO_PKG_BUILD_PKG:=v2ray.com/core/infra/control/main)
	$(call GoPackage/Build/Compile,-ldflags "-s -w")
	mv -f $(GO_PKG_BUILD_BIN_DIR)/main $(GO_PKG_BUILD_BIN_DIR)/v2ctl
endef


$(foreach component,$(V2RAY_COMPONENTS), \
  $(eval $(call GoBinPackage,$(component))) \
  $(eval $(call BuildPackage,$(component))) \
)
$(eval $(call BuildPackage,v2ray-assets))

$(eval $(call GoBinPackage,v2ray-core))
$(eval $(call BuildPackage,v2ray-core))
$(eval $(call GoSrcPackage,golang-v2ray-core-dev))
$(eval $(call BuildPackage,golang-v2ray-core-dev))
