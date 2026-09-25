class BlogResponse {
  List<Blog>? blogsList;
  int? totalDocs;
  int? limit;
  int? totalPages;
  int? page;
  int? pagingCounter;
  bool? hasPrevPage;
  bool? hasNextPage;
  int? prevPage;
  int? nextPage;

  BlogResponse({
    this.blogsList,
    this.totalDocs,
    this.limit,
    this.totalPages,
    this.page,
    this.pagingCounter,
    this.hasPrevPage,
    this.hasNextPage,
    this.prevPage,
    this.nextPage,
  });

  factory BlogResponse.fromJson(Map<String, dynamic> json) => BlogResponse(
    blogsList: json["docs"] == null
        ? null
        : List<Blog>.from(json["docs"].map((x) => Blog.fromJson(x))),
    totalDocs: json["totalDocs"],
    limit: json["limit"],
    totalPages: json["totalPages"],
    page: json["page"],
    pagingCounter: json["pagingCounter"],
    hasPrevPage: json["hasPrevPage"],
    hasNextPage: json["hasNextPage"],
    prevPage: json["prevPage"],
    nextPage: json["nextPage"],
  );

  Map<String, dynamic> toJson() => {
    "docs": blogsList == null
        ? null
        : List<dynamic>.from(blogsList!.map((x) => x.toJson())),
    "totalDocs": totalDocs,
    "limit": limit,
    "totalPages": totalPages,
    "page": page,
    "pagingCounter": pagingCounter,
    "hasPrevPage": hasPrevPage,
    "hasNextPage": hasNextPage,
    "prevPage": prevPage,
    "nextPage": nextPage,
  };
}

class Blog {
  String? id;
  String? image;
  String? title;
  String? summary;
  String? content;
  List<String>? tags;
  String? createdAt;
  String? updatedAt;
  int? v;

  Blog({
    this.id,
    this.image,
    this.title,
    this.summary,
    this.content,
    this.tags,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Blog.fromJson(Map<String, dynamic> json) => Blog(
    id: json["_id"] ?? json["id"],
    image: json["image"],
    title: json["title"],
    summary: json["summary"],
    content: json["content"],
    tags: json["tags"] == null
        ? null
        : List<String>.from(json["tags"].map((x) => x)),
    createdAt: json["createdAt"],
    updatedAt: json["updatedAt"],
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "image": image,
    "title": title,
    "content": content,
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((x) => x)),
  };
}
