// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import io.github.micro.piki
import io.github.micro.piqi

Rectangle {
    id: sidebar
    width: 250
    clip: true
    x: collapsed ? -250 : 0
    color: "transparent"

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    property bool reloadingAccount: false
    readonly property string currentPage: root.currentPage
    property bool collapsed: true

    function switchAccount(data) {
        reloadingAccount = true;
        LoginHandler.SetUser(data.account);
        piqi.Login(LoginHandler.GetToken()).then(() => {
            pageStack.currentItem.refresh();
            reloadingAccount = false;
        });
    }
    function removeAccount(data) {
        reloadingAccount = true;
        if (data == null) {
            LoginHandler.RemoveUser(piqi.user).then(() => {
                if (LoginHandler.otherUsers.length > 0)
                    switchAccount(LoginHandler.otherUsers[0]);
                else {
                    piqi.Walkthrough().then(walkthrough => {
                        reloadingAccount = false;
                        accountDialog.close();
                        sidebar.collapsed = true;
                        navigateToPageParm("Welcome", {
                            wkt: walkthrough
                        });
                    });
                }
            });
        } else
            // Removes user > refreshes the cache > removes the lock
            LoginHandler.RemoveUser(data).then(() => LoginHandler.RefreshOtherUsers().then(() => reloadingAccount = false));
    }

    Behavior on x {
        NumberAnimation {
            easing.type: Easing.OutCubic
        }
    }
    Kirigami.Separator {
        height: parent.height
        anchors.right: parent.right
        z: 100
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        Controls.ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true

            Controls.ScrollBar.vertical.policy: Controls.ScrollBar.AlwaysOff
            Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff

            ColumnLayout {
                id: column
                width: scrollView.width
                spacing: 0

                SidebarButton {
                    page: "Home"
                    icon.name: "go-home-symbolic"
                    matchPart: true
                    autoNavigate: false
                    onNavigate: {
                        loading = true;
                        piqi.RecommendedFeed("illust", true, true).then(recommended => {
                            Cache.SynchroniseIllusts(recommended.illusts);
                            navigateToPageParm("Home", {
                                feed: recommended
                            });
                            loading = false;
                        });
                    }
                }
                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.rightMargin: Kirigami.Units.mediumSpacing
                    Layout.leftMargin: Kirigami.Units.mediumSpacing
                }
                SidebarButton {
                    page: "Following"
                    icon.name: "group"
                    matchPart: true
                    autoNavigate: false
                    onNavigate: {
                        loading = true;
                        piqi.FollowingFeed("illust", "all").then(following => {
                            Cache.SynchroniseIllusts(following.illusts);
                            navigateToPageParm("Following", {
                                feed: following
                            });
                            loading = false;
                        });
                    }
                }
                SidebarButton {
                    page: "Watchlist"
                    icon.name: "view-visible"
                    matchPart: true
                    autoNavigate: false

                    enabled: false
                }
                SidebarButton {
                    page: "My pixiv"
                    icon.source: "qrc:/qt/qml/io/github/micro/piki/contents/assets/io.github.micro.piki.svg"
                    matchPart: true
                    autoNavigate: false

                    enabled: false
                }
                SidebarButton {
                    page: "Newest"
                    icon.name: "view-pim-news"
                    matchPart: true
                    autoNavigate: false

                    onNavigate: {
                        loading = true;
                        piqi.LatestGlobal("illust").then(latest => {
                            Cache.SynchroniseIllusts(latest.illusts);
                            navigateToPageParm("Newest", {
                                feed: latest
                            });
                            loading = false;
                        });
                    }
                }
                Kirigami.Separator {
                    Layout.fillWidth: true
                    Layout.rightMargin: Kirigami.Units.mediumSpacing
                    Layout.leftMargin: Kirigami.Units.mediumSpacing
                }
                SidebarButton {
                    page: "Bookmarks"
                    icon.name: "bookmarks"
                    matchPart: true
                    autoNavigate: false

                    onNavigate: {
                        loading = true;
                        piqi.BookmarksFeed("illust", "public").then(bkmarks => {
                            Cache.SynchroniseIllusts(bkmarks.illusts);
                            navigateToPageParm("Collection", {
                                feed: bkmarks
                            });
                            loading = false;
                        });
                    }
                }
                SidebarButton {
                    page: "History"
                    icon.name: "view-history"
                    matchPart: true
                    autoNavigate: false

                    enabled: false
                }
            }
        }
        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.leftMargin: Kirigami.Units.smallSpacing
        }
        SidebarButton {
            id: accountButton
            page: piqi.user?.name ?? ""
            icon.source: (piqi.user == null) ? "../assets/pixiv_no_profile.png" : piqi.user?.profileImageUrls?.px50 ?? ""
            autoNavigate: false
            // onNavigate: // TODO
            onPressAndHold: accountDialog.open()

            Controls.Button {
                flat: true
                icon.name: "folder-image-people-symbolic"
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    margins: Kirigami.Units.largeSpacing
                }
                onClicked: accountDialog.open()
            }
        }
        SidebarButton {
            visible: Config.enablePremiumSuggestions && !piqi.user.isPremium
            page: "pixiv Premium"
            icon.name: "favorite"
            icon.color: "gold"
            autoNavigate: false
            onNavigate: navigateToPage("Premium")
        }
        SidebarButton {
            page: "Settings"
            icon.name: "configure"
        }
    }

    AccountsManager {
        id: accountDialog

        reloadingAccount: sidebar.reloadingAccount
    }
}
