//
//  SearchViewController.swift
//  GithubUserSearch
//
//  Created by joonwon lee on 2022/05/25.
//

import UIKit
import Combine

class SearchViewController: UIViewController {
    
    let network = NetworkService(configuration: .default)
    
    @Published private(set) var users: [SearchResult] = []
    var subscriptions = Set<AnyCancellable>()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    typealias Item = SearchResult
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        embedSearchController()
        configureCollectionView()
        bind()
    }
    
    // TODO:
    // searchController
    // collectionView 구성
    // bind()
    // - 데이터 -> 뷰
    //   - 검색된 사용자를 collectionView에 업데이트 하는 것
    // - 사용자 인터랙션 대응
    //   - 서치컨트롤에서 텍스트 -> 네트워크 요청
    
    private func embedSearchController() {
        self.navigationItem.title = "Search"
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "someng2"
        searchController.searchResultsUpdater = self    // 타이핑 실시간 업데이트 받기 위한 delegate
        searchController.searchBar.delegate = self      // 서치 버튼 눌렀을 때 반응하는 것
        self.navigationItem.searchController = searchController
    }
    
    private func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ResultCell", for: indexPath) as? ResultCell else { return nil }
            
            cell.user.text = item.login     // 로그인 아이디
            return cell
        })
        
        collectionView.collectionViewLayout = layout()
    }
    
    private func layout() -> UICollectionViewCompositionalLayout {
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func bind() {
        $users
            .receive(on: RunLoop.main)
            .sink { users in
                var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                snapshot.appendSections([.main])
                snapshot.appendItems(users, toSection: .main)
                self.datasource.apply(snapshot)
            }.store(in: &subscriptions)
        
    }
    
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let keyword = searchController.searchBar.text
        print("search: \(keyword)")
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("button clicked: \(searchBar.text)")
        
        
        // - 사용자 인터랙션 대응
        //   - 서치컨트롤에서 텍스트 -> 네트워크 요청
        
        guard let keyword = searchBar.text, !keyword.isEmpty else { return }
        //        let base = "https://api.github.com/"
        //        let path = "search/users"
        //        let params: [String: String] = ["q":keyword]
        //        let header: [String: String] = ["Content-Type": "application/json"]
        //
        //        var urlComponents = URLComponents(string: base + path)!
        //        let queryItems = params.map { (key: String, value: String) in
        //            return URLQueryItem(name: key, value: value)
        //        }
        //        urlComponents.queryItems = queryItems
        //
        //        var request = URLRequest(url: urlComponents.url!)
        //        header.forEach { (key: String, value: String) in
        //            request.addValue(value, forHTTPHeaderField: key)
        //        }
        
        let resource = Resource<SearchUserResponse>(
            base: "https://api.github.com/",
            path: "search/users",
            params: ["q":keyword],
            header: ["Content-Type": "application/json"])
        

//        URLSession.shared.dataTaskPublisher(for: request)
//            .map { $0.data }
//            .decode(type: SearchUserResponse.self, decoder: JSONDecoder())
//            .map { $0.items }   //  사용자
//            .replaceError(with: [])     // 에러 핸들링
//            .receive(on: RunLoop.main)
//            .assign(to: \.users, on: self)  // sink 대신. 데이터 바로 꽂아버림
//            .store(in: &subscriptions)
        
        network.load(resource)
            .map { $0.items }   //  사용자
            .replaceError(with: [])     // 에러 핸들링
            .receive(on: RunLoop.main)
            .assign(to: \.users, on: self)
            .store(in: &subscriptions)
        
    }
    
    
}
